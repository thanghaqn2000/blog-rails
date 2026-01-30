class Message < ApplicationRecord
  belongs_to :conversation

  # Enum cho role: user = 0, assistant = 1, system = 2
  enum role: { user: 0, assistant: 1, system: 2 }
  
  # Enum cho status: success = 0, failed = 1, pending = 2
  enum status: { success: 0, failed: 1, pending: 2 }

  validates :conversation_id, presence: true
  validates :content, presence: true

  after_create :increment_conversation_message_count
  after_create :update_conversation_timestamp

  # Không cần scopes này nữa, enum tự động tạo:
  # - Message.user, Message.assistant, Message.system (cho role)
  # - Message.success, Message.failed, Message.pending (cho status)
  
  scope :recent, -> { order(created_at: :desc) }
  scope :oldest_first, -> { order(created_at: :asc) }
  scope :successful, -> { success }  # Alias cho Message.success
  scope :failed_messages, -> { failed }  # Alias cho Message.failed

  # Không cần các methods này nữa, enum tự động tạo:
  # - user?, assistant?, system? (check role)
  # - success?, failed?, pending? (check status)
  # - user!, assistant!, system! (set role)
  # - success!, failed!, pending! (set status)

  private

  def increment_conversation_message_count
    conversation.increment_message_count!
  end

  def update_conversation_timestamp
    conversation.touch
  end
end
