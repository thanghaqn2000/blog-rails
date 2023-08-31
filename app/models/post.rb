class Post < ApplicationRecord
  acts_as_paranoid

  belongs_to :admin
  belongs_to :category
end
