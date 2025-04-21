class Post < ApplicationRecord
  include Rails.application.routes.url_helpers

  acts_as_paranoid
  enum category: { news: 0, finance: 1 }
  enum status: { pending: 0, publish: 1 }

  belongs_to :user, optional: true
  has_one_attached :image

  def image_url
    return unless image.attached?

    url_for(image)
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[title content created_at updated_at]
  end
end
