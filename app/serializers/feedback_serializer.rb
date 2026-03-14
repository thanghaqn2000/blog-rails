class FeedbackSerializer < ActiveModel::Serializer
  attributes :id, :title, :content, :page_issue, :image_url, :phone_number, :status, :created_at, :updated_at, :user_name

  def user_name
    object.user&.name
  end
end
