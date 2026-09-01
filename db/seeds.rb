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
      lesson_schedule: true,
      homework_assignments: true,
      payment_tracking: false,
      lesson_recording: true,
      student_goals: true,
      ai_homework_generation: false
    }
  },
  {
    name: "pro",
    price: 10,
    stripe_price_id: "price_1SznDlAkHFmsFUgnSFS8RrhD",
    features: {
      max_students: "Unlimited",
      lesson_schedule: true,
      homework_assignments: true,
      payment_tracking: true,
      lesson_recording: true,
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
