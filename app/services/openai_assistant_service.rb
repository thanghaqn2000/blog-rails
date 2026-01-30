require 'openai'

class OpenaiAssistantService
  attr_reader :client, :assistant_id

  def initialize
    @client = OpenAI::Client.new(access_token: ENV['CHATBOT_API_KEY'])
    @assistant_id = ENV['OPENAI_ASSISTANT_ID']
  end

  # Tạo thread mới
  def create_thread
    response = client.threads.create(parameters: {})
    response.dig('id')
  rescue StandardError => e
    Rails.logger.error("OpenAI create thread error: #{e.message}")
    raise OpenAIServiceError, "Không thể tạo thread: #{e.message}"
  end

  # Gửi message và nhận response
  def send_message(thread_id:, content:)
    # 1. Thêm message của user vào thread
    message_response = client.messages.create(
      thread_id: thread_id,
      parameters: {
        role: 'user',
        content: content
      }
    )

    user_message_id = message_response.dig('id')

    # 2. Chạy assistant với vector store cho File Search
    run_params = {
      assistant_id: assistant_id,
      tool_resources: {
        file_search: {
          vector_store_ids: [ENV['OPENAI_VECTOR_STORE_ID']]
        }
      }
    }
    
    Rails.logger.info "🔍 OpenAI Run Parameters: #{run_params.inspect}"
    Rails.logger.info "🔍 Vector Store ID: #{ENV['OPENAI_VECTOR_STORE_ID']}"
    
    run_response = client.runs.create(
      thread_id: thread_id,
      parameters: run_params
    )

    run_id = run_response.dig('id')

    # 3. Chờ run hoàn thành
    run = wait_for_run_completion(thread_id: thread_id, run_id: run_id)

    # 4. Lấy response từ assistant
    assistant_response = fetch_latest_assistant_message(thread_id: thread_id)

    {
      success: true,
      user_message_id: user_message_id,
      assistant_message_id: assistant_response[:message_id],
      assistant_content: assistant_response[:content],
      token_usage: run.dig('usage', 'total_tokens') || 0
    }
  rescue StandardError => e
    Rails.logger.error("OpenAI send message error: #{e.message}")
    {
      success: false,
      error: e.message
    }
  end

  # Lấy tất cả messages trong thread
  def list_messages(thread_id:, limit: 20)
    response = client.messages.list(
      thread_id: thread_id,
      parameters: { limit: limit }
    )
    response.dig('data') || []
  rescue StandardError => e
    Rails.logger.error("OpenAI list messages error: #{e.message}")
    []
  end

  private

  # Chờ run hoàn thành (với timeout)
  def wait_for_run_completion(thread_id:, run_id:, timeout: 60)
    start_time = Time.current
    loop do
      run = client.runs.retrieve(thread_id: thread_id, id: run_id)
      status = run.dig('status')

      case status
      when 'completed'
        return run
      when 'failed', 'cancelled', 'expired'
        raise OpenAIServiceError, "Run failed with status: #{status}"
      end

      # Check timeout
      if Time.current - start_time > timeout
        raise OpenAIServiceError, "Run timeout after #{timeout} seconds"
      end

      sleep 1 # Đợi 1 giây trước khi check lại
    end
  end

  # Lấy message mới nhất từ assistant
  def fetch_latest_assistant_message(thread_id:)
    messages = list_messages(thread_id: thread_id, limit: 1)
    latest_message = messages.first

    if latest_message && latest_message['role'] == 'assistant'
      content = extract_message_content(latest_message)
      {
        message_id: latest_message['id'],
        content: content
      }
    else
      raise OpenAIServiceError, "No assistant message found"
    end
  end

  # Extract content từ message object
  def extract_message_content(message)
    content_array = message.dig('content')
    return '' unless content_array.is_a?(Array)

    # Lấy text content
    text_contents = content_array.select { |c| c['type'] == 'text' }
    text_contents.map { |c| c.dig('text', 'value') }.join("\n")
  end
end

# Custom error class
class OpenAIServiceError < StandardError; end
