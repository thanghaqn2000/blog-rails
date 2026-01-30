class Conversation < ApplicationRecord
  belongs_to :user
  has_many :messages, dependent: :destroy

  # Enum cho status: active = 0, archived = 1, deleted = 2
  enum status: { active: 0, archived: 1, deleted: 2 }

  validates :user_id, presence: true

  before_create :set_default_title

  # Scope 'active' tự động được tạo bởi enum
  scope :recent, -> { order(last_message_at: :desc, updated_at: :desc) }
  # Không cần scope by_status nữa, dùng enum scopes: Conversation.active, .archived, .deleted

  def increment_message_count!
    increment!(:message_count)
    update_column(:last_message_at, Time.current)
  end

  def generate_title_from_first_message
    first_message = messages.where(role: :user).first
    if first_message && (title.blank? || title == "New Conversation")
      # Lấy 50 ký tự đầu tiên làm title
      update(title: first_message.content.truncate(50))
    end
  end

  # Không cần các methods này nữa, enum tự động tạo:
  # - archived! (set status = archived)
  # - deleted! (set status = deleted)
  # - active! (set status = active)
  # - archived? (check status == archived)
  # - deleted? (check status == deleted)
  # - active? (check status == active)

  private

  def set_default_title
    self.title ||= "New Conversation"
    self.last_message_at ||= Time.current
  end
end
