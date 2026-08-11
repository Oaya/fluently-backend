require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "is valid with valid attributes" do
    user = User.new(
      first_name: "Aya",
      last_name: "Okizaki",
      email: "user-#{SecureRandom.hex(4)}@example.com",
      status: "active",
      role: "student",
      password: "password123",
      password_confirmation: "password123",
      confirmed_at: Time.current
    )

    assert user.valid?
  end

  test "requires first_name" do
    user = User.new(
      last_name: "Okizaki",
      email: "user-#{SecureRandom.hex(4)}@example.com",
      status: "active",
      password: "password123",
      password_confirmation: "password123",
      confirmed_at: Time.current
    )

    assert_not user.valid?
    assert_includes user.errors[:first_name], "can't be blank"
  end

  test "requires last_name" do
    user = User.new(
      first_name: "Aya",
      email: "user-#{SecureRandom.hex(4)}@example.com",
      status: "active",
      password: "password123",
      password_confirmation: "password123",
      confirmed_at: Time.current
    )

    assert_not user.valid?
    assert_includes user.errors[:last_name], "can't be blank"
  end

  test "requires email" do
    user = User.new(
      first_name: "Aya",
      last_name: "Okizaki",
      status: "active",
      password: "password123",
      password_confirmation: "password123",
      confirmed_at: Time.current
    )

    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "requires role" do
    user = User.new(
      first_name: "Aya",
      last_name: "Okizaki",
      email: "user-#{SecureRandom.hex(4)}@example.com",
      status: "active",
      role: nil,
      password: "password123",
      password_confirmation: "password123",
      confirmed_at: Time.current
    )

    assert_not user.valid?
    assert_includes user.errors[:role], "can't be blank"
  end

  test "requires status" do
    user = User.new(
      first_name: "Aya",
      last_name: "Okizaki",
      email: "user-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      password_confirmation: "password123",
      confirmed_at: Time.current,
      status: nil
    )

    assert_not user.valid?
    assert_includes user.errors[:status], "can't be blank"
  end

  test "requires unique email case insensitively" do
    email = "test-#{SecureRandom.hex(4)}@example.com"

    User.create!(
      first_name: "Aya",
      last_name: "One",
      email: email,
      status: "active",
      password: "password123",
      password_confirmation: "password123",
      confirmed_at: Time.current
    )

    duplicate = User.new(
      first_name: "Aya",
      last_name: "Two",
      email: email.upcase,
      status: "active",
      password: "password123",
      password_confirmation: "password123",
      confirmed_at: Time.current
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email], "has already been taken"
  end

  test "accepts valid status values" do
    user = User.new(
      first_name: "Aya",
      last_name: "Okizaki",
      email: "user-#{SecureRandom.hex(4)}@example.com",
      status: "active",
      password: "password123",
      password_confirmation: "password123",
      confirmed_at: Time.current
    )

    assert user.valid?
    assert user.active?
  end

  test "rejects invalid status values" do
    user = User.new(
      first_name: "Aya",
      last_name: "Okizaki",
      email: "user-#{SecureRandom.hex(4)}@example.com",
      status: "wrong_status",
      password: "password123",
      password_confirmation: "password123",
      confirmed_at: Time.current
    )

    assert_not user.valid?
    assert_includes user.errors[:status], "is not included in the list"
  end

  test "filter_by_status returns matching users" do
    active_user = create_user(
      email: "active-#{SecureRandom.hex(4)}@example.com",
      status: "active"
    )

    invited_user = create_user(
      email: "invited-#{SecureRandom.hex(4)}@example.com",
      status: "invited"
    )

    results = User.filter_by_status("active")

    assert_includes results, active_user
    assert_not_includes results, invited_user
  end

  test "filter_by_role returns matching users" do
    admin_user = create_user(
      email: "admin-#{SecureRandom.hex(4)}@example.com",
      role: "admin"
    )

    student_user = create_user(
      email: "student-#{SecureRandom.hex(4)}@example.com",
      role: "student"
    )

    results = User.filter_by_role("admin")

    assert_includes results, admin_user
    assert_not_includes results, student_user
  end

  test "filter_by_search matches first name last name and email" do
    matching_user = create_user(
      first_name: "Aya",
      last_name: "Okizaki",
      email: "aya-#{SecureRandom.hex(4)}@example.com"
    )

    other_user = create_user(
      first_name: "John",
      last_name: "Smith",
      email: "john-#{SecureRandom.hex(4)}@example.com"
    )

    assert_includes User.filter_by_search("Aya"), matching_user
    assert_includes User.filter_by_search("Okizaki"), matching_user
    assert_includes User.filter_by_search("aya-"), matching_user
    assert_not_includes User.filter_by_search("Aya"), other_user
  end
end
