require "test_helper"

class TenantTest < ActiveSupport::TestCase
  test "is valid with valid attributes" do
    plan = create_plan

    tenant = Tenant.new(
      name: "Tenant #{SecureRandom.hex(4)}",
      plan: plan,
      status: "active"
    )

    assert tenant.valid?
  end

  test "requires a name" do
    plan = create_plan

    tenant = Tenant.new(
      plan: plan,
      status: "active"
    )

    assert_not tenant.valid?
    assert_includes tenant.errors[:name], "can't be blank"
  end

  test "requires unique name" do
    plan = create_plan
    name = "Tenant #{SecureRandom.hex(4)}"

    Tenant.create!(
      name: name,
      plan: plan,
      status: "active"
    )

    duplicate = Tenant.new(
      name: name,
      plan: plan,
      status: "pending"
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "requires a plan" do
    tenant = Tenant.new(
      name: "Tenant #{SecureRandom.hex(4)}",
      status: "active"
    )

    assert_not tenant.valid?
    assert_includes tenant.errors[:plan], "must exist"
  end

  test "accepts valid status values" do
    plan = create_plan

    tenant = Tenant.new(
      name: "Tenant #{SecureRandom.hex(4)}",
      plan: plan,
      status: "active"
    )

    assert tenant.valid?
    assert tenant.active?
  end

  test "rejects invalid status values" do
    plan = create_plan

    tenant = Tenant.new(
      name: "Tenant #{SecureRandom.hex(4)}",
      plan: plan,
      status: "invalid_status"
    )

    assert_not tenant.valid?
    assert_includes tenant.errors[:status], "is not included in the list"
  end

  test "allows nil stripe_subscription_id" do
    plan = create_plan

    tenant = Tenant.new(
      name: "Tenant #{SecureRandom.hex(4)}",
      plan: plan,
      status: "active",
      stripe_subscription_id: nil
    )

    assert tenant.valid?
  end

  test "requires unique stripe_subscription_id when present" do
    plan = create_plan
    stripe_subscription_id = "sub_#{SecureRandom.hex(6)}"

    Tenant.create!(
      name: "Tenant #{SecureRandom.hex(4)}",
      plan: plan,
      status: "active",
      stripe_subscription_id: stripe_subscription_id
    )

    duplicate = Tenant.new(
      name: "Tenant #{SecureRandom.hex(4)}",
      plan: plan,
      status: "pending",
      stripe_subscription_id: stripe_subscription_id
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:stripe_subscription_id], "has already been taken"
  end

  test "allows nil stripe_customer_id" do
    plan = create_plan

    tenant = Tenant.new(
      name: "Tenant #{SecureRandom.hex(4)}",
      plan: plan,
      status: "active",
      stripe_customer_id: nil
    )

    assert tenant.valid?
  end

  test "requires unique stripe_customer_id when present" do
    plan = create_plan
    stripe_customer_id = "cus_#{SecureRandom.hex(6)}"

    Tenant.create!(
      name: "Tenant #{SecureRandom.hex(4)}",
      plan: plan,
      status: "active",
      stripe_customer_id: stripe_customer_id
    )

    duplicate = Tenant.new(
      name: "Tenant #{SecureRandom.hex(4)}",
      plan: plan,
      status: "pending",
      stripe_customer_id: stripe_customer_id
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:stripe_customer_id], "has already been taken"
  end

  test "can belong to a billing owner" do
    plan = create_plan
    tenant = create_tenant(plan: plan)

    user = create_user(tenant: tenant)

    tenant.billing_owner = user

    assert tenant.valid?
    assert_equal user, tenant.billing_owner
  end
end
