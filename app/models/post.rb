class Post < ApplicationRecord
  acts_as_paranoid
  enum category: { news: 0, finance: 1 }
  enum status: { pending: 0, publish: 1 }

  belongs_to :admin, optional: true
end
