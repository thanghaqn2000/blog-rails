class Api::V1::MessagesController < ApplicationController
  include QuotaChecker

  before_action :set_conversation
  before_action :check_quota!, only: :create

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

  private

  def set_conversation
    @conversation = @current_user.conversations.find(params[:conversation_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Conversation not found' }, status: :not_found
  end

  def message_params
    params.require(:message).permit(:content)
  end
end
