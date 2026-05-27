class SeedPlans < ActiveRecord::Migration[8.0]
  def up
    plans = [
      {
        name: "basic",
        price: 0,
        stripe_price_id: nil,
        features: { max_courses: 10, max_admin: 2, max_users: 100, quizzes: false }
      },
      {
        name: "standard",
        price: 10,
        stripe_price_id: "price_1SznDlAkHFmsFUgnSFS8RrhD",
        features: { max_courses: 30, max_admin: 5, max_users: 500, quizzes: true }
      },
      {
        name: "premium",
        price: 30,
        stripe_price_id: "price_1SznEgAkHFmsFUgnPED89bPF",
        features: { max_courses: 100, max_admin: 10, max_users: 1000, quizzes: true }
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
