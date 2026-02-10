class SlideSerializer < ActiveModel::Serializer
  attributes :id, :heading, :description, :image_url, :created_at, :updated_at
end

