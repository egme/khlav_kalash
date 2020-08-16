FactoryBot.define do
  factory :order do
    amount_cents { Order::UNIT_PRICE_CENTS }
    first_name { Faker::Name.first_name }
    last_name  { Faker::Name.last_name }
    street_line_1 { Faker::Address.street_address }
    street_line_2 { Faker::Address.secondary_address }
    postal_code { Faker::Address.zip_code }
    region { Faker::Address.state }
    city { Faker::Address.city }
    country { Faker::Address.country_code }
    email_address { Faker::Internet.email }
    number { nil }
    permalink { nil }
    payment_intent_id { nil }
    paid_at { nil }
  end
end
