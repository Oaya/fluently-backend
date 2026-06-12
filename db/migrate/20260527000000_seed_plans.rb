class SeedPlans < ActiveRecord::Migration[8.0]
  def up
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

    plans.each do |attrs|
      Plan.find_or_create_by!(name: attrs[:name]) do |plan|
        plan.price = attrs[:price]
        plan.stripe_price_id = attrs[:stripe_price_id]
        plan.features = attrs[:features]
      end
    end
  end

  def down
    Plan.where(name: %w[basic standard premium]).destroy_all
  end
end
