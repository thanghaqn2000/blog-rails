class PostRepresenter < Representable::Decorator
  include Representable::JSON

  property :id
  property :title
  property :content
  property :created_at
  property :updated_at
  property :image_url
  property :category
  property :status

  def image_url
    represented.image_url
  end
end
