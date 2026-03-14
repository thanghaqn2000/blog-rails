class Feedback < ApplicationRecord
  belongs_to :user

  enum status: { waiting: 0, done: 1 }

  validates :title, presence: true
  validates :content, presence: true

  def self.ransackable_attributes(auth_object = nil)
    %w[title content created_at updated_at phone_number status]
  end
end
