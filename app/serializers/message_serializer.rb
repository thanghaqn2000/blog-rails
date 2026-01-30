class MessageSerializer < ActiveModel::Serializer
  attributes :id, :conversation_id, :role, :content, :openai_message_id, :token_usage, :status, :created_at

  def created_at
    object.created_at.iso8601
  end
end
