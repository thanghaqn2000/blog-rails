class Post < ApplicationRecord
  acts_as_paranoid
  enum category: { news: 0, finance: 1 }

  belongs_to :admin
end
