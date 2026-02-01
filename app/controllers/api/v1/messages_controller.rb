class Api::V1::MessagesController < ApplicationController
  include QuotaChecker
  include ActionController::Live

  before_action :set_conversation
  before_action :check_quota!, only: [:create, :stream]

  # GET /api/v1/conversations/:conversation_id/messages
  def index
    messages = @conversation.messages
                           .oldest_first
                           .page(params[:page])
                           .per(params[:per_page] || 50)

    render json: messages, each_serializer: MessageSerializer
  end

  # POST /api/v1/conversations/:conversation_id/messages
  def create
    content = message_params[:content]

    if content.blank?
      render json: { error: 'Content không được để trống' }, status: :bad_request
      return
    end

    # Tạo user message với status pending
    user_message = @conversation.messages.build(
      role: :user,  # Enum
      content: content,
      status: :pending  # Enum
    )

    begin
      # Gọi OpenAI Assistant API
      openai_service = OpenaiAssistantService.new
      response = openai_service.send_message(
        thread_id: @conversation.openai_thread_id,
        content: content
      )

      if response[:success]
        # Cập nhật user message thành công
        user_message.success!  # Enum method
        user_message.openai_message_id = response[:user_message_id]
        user_message.save!

        # Tạo assistant message
        assistant_message = @conversation.messages.create!(
          role: :assistant,  # Enum
          content: response[:assistant_content],
          openai_message_id: response[:assistant_message_id],
          token_usage: response[:token_usage],
          status: :success  # Enum
        )

        # Tăng quota (chỉ khi thành công)
        increment_quota!

        # Generate title từ message đầu tiên
        @conversation.generate_title_from_first_message if @conversation.message_count == 2

        render json: {
          user_message: MessageSerializer.new(user_message),
          assistant_message: MessageSerializer.new(assistant_message)
        }, status: :created

      else
        # OpenAI API failed
        user_message.failed!  # Enum method

        render json: {
          error: 'OpenAI API failed',
          message: response[:error],
          user_message: MessageSerializer.new(user_message)
        }, status: :service_unavailable
      end

    rescue OpenAIServiceError => e
      # Lỗi từ OpenAI service
      if user_message.new_record?
        user_message.failed!
        user_message.save!
      else
        user_message.failed!
      end

      render json: {
        error: 'OpenAI Service Error',
        message: e.message,
        user_message: MessageSerializer.new(user_message)
      }, status: :service_unavailable

    rescue StandardError => e
      # Lỗi không xác định
      Rails.logger.error("Message creation error: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))

      if user_message.new_record?
        user_message.failed!
        user_message.save!
      else
        user_message.failed!
      end

      render json: {
        error: 'Internal Server Error',
        message: e.message
      }, status: :internal_server_error
    end
  end

  # POST /api/v1/conversations/:conversation_id/messages/stream
  # SSE Streaming endpoint
  def stream
    content = message_params[:content]

    if content.blank?
      render json: { error: 'Content không được để trống' }, status: :bad_request
      return
    end

    # Set SSE headers (proxy-friendly for staging/production)
    response.headers['Content-Type'] = 'text/event-stream'
    response.headers['Cache-Control'] = 'no-cache, no-store'
    response.headers['X-Accel-Buffering'] = 'no'   # Nginx: disable buffering
    response.headers['Connection'] = 'keep-alive'

    user_message = nil
    client_disconnected = false

    begin
      # Gửi comment ngay để proxy không buffer (phải nằm trong begin để bắt disconnect)
      response.stream.write(": \n\n")

      # 1. Lưu user message ngay (status: pending)
      ActiveRecord::Base.connection_pool.with_connection do
        user_message = @conversation.messages.create!(
          role: :user,
          content: content,
          status: :pending
        )
      end

      # 2. Send initial event với user_message
      sse_write('user_message', MessageSerializer.new(user_message).as_json)

      # 3. Stream từ OpenAI
      openai_service = OpenaiAssistantService.new
      full_content = ''
      assistant_message_id = nil
      openai_user_message_id = nil
      token_usage = 0

      openai_service.send_message_stream(
        thread_id: @conversation.openai_thread_id,
        content: content
      ) do |event|
        case event[:type]
        when 'user_message_id'
          openai_user_message_id = event[:content]

        when 'chunk'
          # Stream text chunk đến frontend
          full_content += event[:content]
          sse_write('chunk', { content: event[:content] })

        when 'done'
          # Streaming hoàn tất
          assistant_message_id = event[:assistant_message_id]
          token_usage = event[:token_usage]
          full_content = event[:full_content] if event[:full_content].present?

          # 4-7. All DB operations in separate connection blocks
          assistant_message = nil
          
          ActiveRecord::Base.connection_pool.with_connection do
            # Lưu assistant message
            assistant_message = @conversation.messages.create!(
              role: :assistant,
              content: full_content,
              openai_message_id: assistant_message_id,
              token_usage: token_usage,
              status: :success
            )

            # Update user message
            user_message.update!(
              openai_message_id: openai_user_message_id,
              status: :success
            )

            # Tăng quota
            increment_quota!

            # Generate title từ message đầu tiên
            @conversation.generate_title_from_first_message if @conversation.message_count == 2
          end

          # 8. Send done event (outside connection block)
          sse_write('done', {
            user_message: MessageSerializer.new(user_message).as_json,
            assistant_message: MessageSerializer.new(assistant_message).as_json
          })

        when 'error'
          # OpenAI error
          raise OpenAIServiceError, event[:error]
        end
      end

    rescue IOError, ActionController::Live::ClientDisconnected => e
      # Client disconnected (user clicked stop button)
      client_disconnected = true
      Rails.logger.warn("Client disconnected during streaming: #{e.message}")
      
      # Update user message status to failed
      if user_message&.persisted?
        ActiveRecord::Base.connection_pool.with_connection do
          user_message.update(status: :failed)
        end
      end
      
      # Không tăng quota khi client disconnect

    rescue OpenAIServiceError => e
      # Lỗi từ OpenAI - không lưu assistant message, không tăng quota
      ActiveRecord::Base.connection_pool.with_connection do
        user_message.update(status: :failed) if user_message
      end
      
      sse_write('error', {
        error: 'OpenAI Service Error',
        message: e.message
      })

    rescue StandardError => e
      # Lỗi không xác định
      Rails.logger.error("Streaming error: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      
      if user_message&.persisted?
        ActiveRecord::Base.connection_pool.with_connection do
          user_message.update(status: :failed)
        end
      end
      
      sse_write('error', {
        error: 'Internal Server Error',
        message: e.message
      })

    ensure
      # Đóng SSE stream
      begin
        response.stream.close unless client_disconnected
      rescue IOError, ActionController::Live::ClientDisconnected
        # Stream already closed by client
      end
    end
  end

  private

  # Helper để write SSE event
  def sse_write(event_name, data)
    response.stream.write("event: #{event_name}\n")
    response.stream.write("data: #{data.to_json}\n\n")
  rescue IOError, ActionController::Live::ClientDisconnected => e
    # Client đã disconnect - re-raise để handle ở stream method
    raise e
  end

  def set_conversation
    @conversation = @current_user.conversations.find(params[:conversation_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Conversation not found' }, status: :not_found
  end

  def message_params
    params.require(:message).permit(:content)
  end
end
