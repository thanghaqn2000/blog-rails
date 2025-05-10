class PostSerializer < ActiveModel::Serializer
  attributes :id, :title, :content, :created_at, :updated_at, :image_url, :category, :status, :author

  def image_url
    object.image_url
  end

  def author
    object&.user&.name
  end
end
