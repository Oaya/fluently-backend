# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
require "faker"

plans = [
  {
    name: "free",
    price: 0,
    features: {
      max_students: 3,
      session_schedule: true,
      homework_assignments: true,
      payment_tracking: false,
      session_recording: true,
      student_goals: true,
      ai_homework_generation: false
    }
  },
  {
    name: "pro",
    price: 10,
    stripe_price_id: "price_1SznDlAkHFmsFUgnSFS8RrhD",
    features: {
      max_students: "unlimited",
      session_schedule: true,
      homework_assignments: true,
      payment_tracking: true,
      session_recording: true,
      student_goals: true,
      ai_homework_generation: true
    }
  }
]

plans.each do |plan|
  Plan.find_or_create_by!(name: plan[:name]) do |p|
    p.price = plan[:price]
    p.stripe_price_id = plan[:stripe_price_id]
    p.features = plan[:features]
  end
end

free_plan = Plan.find_by!(name: "free")

admin_user = User.create!(
  email: "ayaaa.okzk@gmail.com",
  first_name: "Aya",
  last_name: "Okizaki",
  password: "password",
  password_confirmation: "password",
  role: "admin",
  plan: free_plan,
  subscription_status: "active",
  status: "active",
  confirmed_at: Time.current
)

pp "Created admin user: #{admin_user.email}"

10.times do
  role = Faker::Boolean.boolean(true_ratio: 0.2) ? "instructor" : "student"
  User.create!(
    email: Faker::Internet.unique.email,
    first_name: Faker::Name.first_name,
    last_name: Faker::Name.last_name,
    role: role,
    status: "active",
    password: "password",
    password_confirmation: "password",
    confirmed_at: Time.current
  )
end

pp "Created 10 additional users"

load Rails.root.join("db/seeds/courses.rb")
