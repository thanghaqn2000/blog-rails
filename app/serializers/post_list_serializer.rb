class PostListSerializer < ActiveModel::Serializer
  attributes :id, :title, :created_at, :updated_at, :image_url, :category,
             :status, :sub_type, :date_post, :author, :description

  def image_url
    object.image_url
  end

  def author
    object&.user&.name
  end
end
