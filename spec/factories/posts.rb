FactoryBot.define do
  factory :post do
    admin {create :admin}
    content {Faker::Lorem.paragraph}
    title {Faker::Book.title}
  end
end
