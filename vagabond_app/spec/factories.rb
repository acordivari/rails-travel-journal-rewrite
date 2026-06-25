FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "Traveler #{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    current_city { "Lisbon" }
    password { "password" }
    admin { false }

    trait :admin do
      admin { true }
    end
  end

  factory :city do
    sequence(:name) { |n| "City #{n}" }
  end

  factory :post do
    sequence(:title) { |n| "A trip to remember ##{n}" }
    body { "This is the story of a wonderful journey worth writing about." }
    association :user
    association :city
  end

  factory :comment do
    body { "Great write-up, thanks for sharing!" }
    association :user
    association :post
  end
end
