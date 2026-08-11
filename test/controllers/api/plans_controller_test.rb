require "test_helper"

class Api::PlansControllerTest < ActionDispatch::IntegrationTest
  test "index returns all plans with limited fields, no authentication required" do
    plan = create_plan(name: "Pro", price: 2000)

    get api_plans_url
    assert_response :success

    plan_json = response.parsed_body.find { |p| p["id"] == plan.id }
    assert_equal "Pro", plan_json["name"]
    assert_equal 2000, plan_json["price"]
    assert_equal plan.features, plan_json["features"]
    assert_not plan_json.key?("stripe_price_id")
  end
end
