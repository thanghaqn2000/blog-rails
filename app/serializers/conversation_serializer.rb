class ConversationSerializer < ActiveModel::Serializer
  attributes :id, :title, :openai_thread_id, :message_count, :status, :last_message_at, :created_at, :updated_at

  has_many :messages, if: -> { instance_options[:include_messages] }

  def last_message_at
    object.last_message_at&.iso8601
  end

  def created_at
    object.created_at.iso8601
  end

  def updated_at
    object.updated_at.iso8601
  end
end
