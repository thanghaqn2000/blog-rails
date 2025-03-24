class PostSerializer < ActiveModel::Serializer
  attributes :id, :title, :content, :created_at, :updated_at, :image_url, :category, :status

  def image_url
    object.image_url
  end
end 
