class User < ApplicationRecord
  acts_as_paranoid

  has_many :comments
end
