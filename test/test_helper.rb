ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "bcrypt"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)


    # Add more helper methods to be used by all tests here...
  end
end


module TestDataHelper
  def create_plan(attrs = {})
    Plan.create!({
      name: "Test Plan",
      price: 10,
      features: { "max_courses" => 10, "max_admin" => 2, "max_users" => 100, "quizzes" => false }
    }.merge(attrs))
  end

  def create_tenant(plan: nil, **attrs)
    plan ||= create_plan

    Tenant.create!({
      name: "Tenant #{SecureRandom.hex(4)}",
      plan: plan,
      status: "active"
    }.merge(attrs))
  end

  def create_user(tenant:, **attrs)
    User.create!({
      email: "user-#{SecureRandom.hex(4)}@example.com",
      first_name: "Test",
      last_name: "User",
      tenant: tenant,
      status: "active",
      password: "password123",
      password_confirmation: "password123",
      confirmed_at: Time.current
    }.merge(attrs))
  end

  def create_course(tenant:, **attrs)
    Course.create!({
      tenant: tenant,
      title: "Course #{SecureRandom.hex(4)}",
      description: "Test course"
    }.merge(attrs))
  end

  def create_section(tenant:, course:, **attrs)
    Section.create!({
      tenant: tenant,
      course: course,
      title: "Section #{SecureRandom.hex(4)}",
      description: "Test section"
    }.merge(attrs))
  end

  def create_lesson(tenant:, section:, **attrs)
    Lesson.create!({
      tenant: tenant,
      section: section,
      title: "Lesson #{SecureRandom.hex(4)}",
      lesson_type: "reading"
    }.merge(attrs))
  end

  def create_enrollment(tenant:, user:, course:, **attrs)
    Enrollment.create!({
      tenant: tenant,
      user: user,
      course: course
    }.merge(attrs))
  end
end
