# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
#
require "faker"

 plans = [
  {
    name: "basic",
    price: 0,
    features: {
      max_courses: 10,
      max_admin: 2,
      max_users: 100,
      quizzes: false
    }
  },
  {
    name: "standard",
    price: 10,
    stripe_price_id: "price_1SznDlAkHFmsFUgnSFS8RrhD",
    features: {
      max_courses: 30,
      max_admin: 5,
      max_users: 500,
      quizzes: true
    }
  },
  {
    name: "premium",
    price: 30,
    stripe_price_id: "price_1SznEgAkHFmsFUgnPED89bPF",
    features: {
      max_courses: 100,
      max_admin: 10,
      max_users: 1000,
      quizzes: true
    }
  }
]

plans.each do |plan|
  pp plan
  Plan.create!(name: plan[:name], price: plan[:price], stripe_price_id: plan[:stripe_price_id], features: plan[:features])
end


tenant = Tenant.create!(name: "Test Tenant", plan: Plan.find_by(name: "basic"), status: "active")

user = User.create!(
  email: "ayaaa.okzk@gmail.com",
  first_name: "Aya",
  last_name: "Okizaki",
  password: "password",
  password_confirmation: "password",
  tenant_id: tenant.id,
  status: "active",
  confirmed_at: Time.current
)

Membership.create!(
  user_id: user.id,
  tenant_id: tenant.id,
  role: "admin"
)
tenant.billing_owner = user
tenant.save!

pp tenant

10.times do
  user =User.create!(
    email: Faker::Internet.unique.email,
    first_name: Faker::Name.first_name,
    last_name: Faker::Name.last_name,
    tenant_id: tenant.id,
    status: "active",
    password: "password",
    password_confirmation: "password",
    confirmed_at: Time.current
  )
  Membership.create!(
    user_id: user.id,
    tenant_id: tenant.id,
    role: Faker::Boolean.boolean(true_ratio: 0.1) ? "admin" : "instructor"
  )
end

pp "Created 10 users for tenant #{tenant.name}"

load Rails.root.join("db/seeds/courses.rb")
