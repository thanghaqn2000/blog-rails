FactoryBot.define do
  factory :user do
    user_name {Faker::Name.unique.name}
    email {Faker::Internet.unique.email}
    password {"Aa@123456"}
    date_of_birth {Faker::Date.between(from: "1900-01-01", to: Date.today)}
  end
end
