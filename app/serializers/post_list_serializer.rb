class PostListSerializer < ActiveModel::Serializer
  attributes :id, :slug, :title, :created_at, :updated_at, :image_url, :category,
             :status, :sub_type, :date_post, :description, :source, :author_type, :author

  def image_url
    object.image_url
  end

  def author
    return nil unless object.user

    {
      name: object.user.name,
      avatar_url: object.user.avatar_url
    }
  end

  def author_type
    object.author_type
  end
end
