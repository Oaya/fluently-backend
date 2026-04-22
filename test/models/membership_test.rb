require "test_helper"
include TestDataHelper

class MembershipTest < ActiveSupport::TestCase
  setup do
    @plan = create_plan

    @tenant = create_tenant(plan: @plan)

    @user = create_user(tenant: @tenant)
  end

  test "user cannot have duplicate membership in same tenant" do
    Membership.create!(
      user: @user,
      tenant: @tenant,
      role: "admin"
    )
  
    duplicate = Membership.new(
      user: @user,
      tenant: @tenant,
      role: "admin"
    )
  
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end

  test "is valid with valid attributes" do
    membership = Membership.new(
      user: @user,
      tenant: @tenant,
      role: "admin"
    )

    assert membership.valid?
  end

  test "same user can belong to different tenants" do
    other_tenant = Tenant.create!(
      name: "Other Tenant #{SecureRandom.hex(4)}",
      plan: @plan,
      status: "active"
    )

    Membership.create!(
      user: @user,
      tenant: @tenant,
      role: "admin"
    )

    membership = Membership.new(
      user: @user,
      tenant: other_tenant,
      role: "admin"
    )

    assert membership.valid?
  end

  test "role must be valid enum value" do
    membership = Membership.new(
      user: @user,
      tenant: @tenant,
      role: "invalid_role"
    )

    assert_not membership.valid?
    assert_includes membership.errors[:role], "is not included in the list"
  end

  test "role enum methods work" do
    membership = Membership.create!(
      user: @user,
      tenant: @tenant,
      role: "student"
    )

    assert membership.student?
    assert_not membership.admin?

    membership.admin!
    assert membership.admin?
  end
end