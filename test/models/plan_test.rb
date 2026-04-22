require "test_helper"

class PlanTest < ActiveSupport::TestCase
  test "is valid with valid attributes" do
    plan = Plan.new(
      name: "Basic #{SecureRandom.hex(4)}",
      price: 1000
    )

    assert plan.valid?
  end

  test "requires name" do
    plan = Plan.new(price: 1000)

    assert_not plan.valid?
    assert_includes plan.errors[:name], "can't be blank"
  end

  test "requires price" do
    plan = Plan.new(name: "Basic")

    assert_not plan.valid?
    assert_includes plan.errors[:price], "can't be blank"
  end

  test "price must be an integer" do
    plan = Plan.new(
      name: "Basic",
      price: 10.5
    )

    assert_not plan.valid?
    assert_includes plan.errors[:price], "must be an integer"
  end

  test "price must be >= 0" do
    plan = Plan.new(
      name: "Basic",
      price: -1
    )

    assert_not plan.valid?
    assert_includes plan.errors[:price], "must be greater than or equal to 0"
  end

  test "accepts integer-like string input" do
    plan = Plan.new(
      name: "Basic",
      price: "1000"
    )

    assert plan.valid?
    assert_equal 1000, plan.price
  end

  test "rejects decimal string input" do
    plan = Plan.new(
      name: "Basic",
      price: "10.5"
    )

    assert_not plan.valid?
    assert_includes plan.errors[:price], "must be an integer"
  end
end