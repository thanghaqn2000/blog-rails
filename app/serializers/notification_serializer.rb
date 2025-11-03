class NotificationSerializer < ActiveModel::Serializer
  attributes :id, :title, :content, :image_url, :link, :type, :status, 
             :scheduled_at, :sent_at, :created_at, :updated_at, :user_info

  def user_info
    {
      id: object.user.id,
      name: object.user.name,
      email: object.user.email
    }
  end
end
