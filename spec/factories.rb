FactoryGirl.define do
  sequence :unique_email do |n|
    "user#{n}s@bikeiasdndex.org"
  end

  sequence :unique_name do |n|
    "Special_name#{n}"
  end

  sequence :serial_number do |n|
    "serial#{n}"
  end

  sequence :name do |n|
    "Mike #{n}ison"
  end

  sequence :slug do |n|
    "bike-shop-#{n}"
  end

  sequence :unique_iso do |n|
    "#{n}0"
  end

  factory :user do
    name
    email { generate(:unique_email)}
    password "testthisthing7$"
    password_confirmation "testthisthing7$"
    terms_of_service true
  end

  factory :bike_token do
    association :user
    association :organization
  end

  factory :bike_token_invitation do
    association :inviter, factory: :user
    association :organization
    message "You've been sent a bike token!"
    subject "Join the Bike Index, we're awesome"
    bike_token_count 1
    invitee_email "george@test.com"
  end

  factory :cycle_type do
    name { FactoryGirl.generate(:unique_name) }
    slug { FactoryGirl.generate(:unique_name) }
  end

  factory :manufacturer do
    name { FactoryGirl.generate(:unique_name) }
    frame_maker true
  end

  factory :frame_material do
    name { FactoryGirl.generate(:unique_name) }
    slug { FactoryGirl.generate(:unique_name) }
  end

  factory :propulsion_type do
    name { FactoryGirl.generate(:unique_name) }
  end

  factory :wheel_size do
    name { FactoryGirl.generate(:unique_name) }
    iso_bsd { FactoryGirl.generate(:unique_iso) }
    priority 1
    description { FactoryGirl.generate(:unique_name) }
  end

  factory :handlebar_type do
    name { FactoryGirl.generate(:unique_name) }
    slug { FactoryGirl.generate(:unique_name) }
  end

  factory :color do
    name { FactoryGirl.generate(:unique_name) }
    priority 1
  end

  factory :paint do
    name { FactoryGirl.generate(:unique_name) }
  end

  factory :b_param do
    association :creator, factory: :user
  end

  factory :bike do
    # Warning: the bikes controller forces every bike to have an ownership
    # But this factory allows creating bikes without ownerships.
    serial_number
    association :cycle_type
    association :manufacturer, factory: :manufacturer
    association :creator, factory: :user
    association :rear_wheel_size, factory: :wheel_size
    # association :handlebar_type
    association :propulsion_type
    association :primary_frame_color, factory: :color
    rear_tire_narrow true
    sequence(:owner_email) {|n| "bike_owner#{n}@example.com"}

    factory :stolen_bike do
      stolen true
      after(:create) do |bike|
        create(:stolen_record, bike: bike)
        bike.save # updates current_stolen_record
      end
    end
  end

  factory :cgroup do
    name { FactoryGirl.generate(:unique_name) }
  end

  factory :ctype do
    sequence(:name) {|n| "Component type#{n}"}
    association :cgroup
  end

  factory :ownership do
    association :bike, factory: :bike
    association :creator, factory: :user
    current true
    sequence(:owner_email) {|n| "owner#{n}@example.com"}
  end

  factory :component do
    association :bike, factory: :bike
    association :ctype
  end

  factory :organization do
    name
    sequence(:short_name) {|n| "short_name#{n}"}
    slug
    default_bike_token_count 5
    available_invitation_count 5
  end

  factory :location do
    name
    association :organization
    association :country
    association :state
    zipcode '60647'
    city 'Chicago'
    street 'foo address'
  end

  factory :country do
    name
    sequence(:iso) {|n| "D#{n}"}
  end

  factory :state do
    name
    association :country
    sequence(:abbreviation) {|n| "Q#{n}"}
  end

  factory :lock_type do
    name { FactoryGirl.generate(:unique_name) }
  end

  factory :lock do
    association :user
    association :manufacturer
    association :lock_type
  end

  factory :organization_invitation do
    association :inviter, factory: :user
    association :organization
    invitee_email "mike@test.com"
  end

  factory :membership do
    role "member"
  end

  factory :integration do
    access_token "12345teststststs"
    provider_name "facebook"
  end

  factory :public_image do |u|
    u.image { File.open(File.join(Rails.root, 'spec', 'factories', 'bike.jpg')) }
    association :imageable, factory: :bike
  end

  factory :feedback do
    email 'foo@boy.com'
    body 'This is a test email.'
    title 'New Feedback Submitted'
    name 'Bobby Joe'
  end

  factory :stolen_notification do
    association :sender, factory: :user
    association :receiver, factory: :user
    association :bike
    message 'This is a test email.'
    subject 'New Stolen Notification Submitted'
  end

  factory :stolen_record do
    bike
    date_stolen Time.now
  end

  factory :customer_contact do
    association :creator, factory: :user
    association :bike
    title 'Some title'
    body 'some message'
    creator_email 'something@example.com'
    user_email 'something_else@example.com'
    contact_type 'stolen_message'
  end

end
