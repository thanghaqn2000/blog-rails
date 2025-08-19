class Post < ApplicationRecord
  acts_as_paranoid
  enum category: { news: 0, finance: 1 }
  enum status: { pending: 0, publish: 1 }

  belongs_to :user, optional: true

  scope :with_category_name, lambda { |name|
    categories.key?(name) ? where(category: categories[name]) : none
  }

  def self.ransackable_scopes(auth_object = nil)
    %i[with_category_name]
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[title content created_at updated_at category]
  end
end
