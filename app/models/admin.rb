class Admin < ApplicationRecord
  acts_as_paranoid

  has_many :posts
end
