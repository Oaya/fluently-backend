ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "bcrypt"
require "rails/test_help"

module TestDataHelper
  def create_plan(attrs = {})
    Plan.create!({
      name: "Test Plan #{SecureRandom.hex(4)}",
      price: 10,
      features: { "max_courses" => 10, "max_admin" => 2, "max_users" => 100, "quizzes" => false }
    }.merge(attrs))
  end

  def create_user(attrs = {})
    User.create!({
      email: "user-#{SecureRandom.hex(4)}@example.com",
      first_name: "Test",
      last_name: "User",
      status: "active",
      role: "student",
      password: "password123",
      password_confirmation: "password123",
      confirmed_at: Time.current
    }.merge(attrs))
  end

  def create_admin(attrs = {})
    create_user({ role: "admin" }.merge(attrs))
  end

  def create_student(admin:, **attrs)
    create_user({ role: "student", admin: admin }.merge(attrs))
  end

  def create_goal(admin:, student:, **attrs)
    Goal.create!({
      admin: admin,
      student: student,
      title: "Goal #{SecureRandom.hex(4)}",
      target_date: 1.month.from_now.to_date
    }.merge(attrs))
  end

  def create_homework(admin:, student:, **attrs)
    Homework.create!({
      admin: admin,
      student: student,
      title: "Homework #{SecureRandom.hex(4)}",
      due_date: 1.week.from_now.to_date,
      ai_generated: false
    }.merge(attrs))
  end

  def create_homework_submission(homework:, student:, **attrs)
    HomeworkSubmission.create!({
      homework: homework,
      student: student,
      status: "draft"
    }.merge(attrs))
  end

  def create_lesson(admin:, student:, **attrs)
    Lesson.create!({
      admin: admin,
      student: student,
      scheduled_at: 1.day.from_now,
      status: "scheduled"
    }.merge(attrs))
  end

  # Generates a devise-jwt token for the `api_user` warden scope, matching
  # how SignInWithJwt issues tokens in the real sign-in flow.
  def auth_header(user)
    jwt, _payload = Warden::JWTAuth::UserEncoder.new.call(user, :api_user, nil)
    { "Authorization" => "Bearer #{jwt}" }
  end

  # Minitest 6 dropped Object#stub (it now lives in the separate minitest-mock
  # gem, which isn't in the Gemfile), so this is a small drop-in replacement
  # for stubbing a class/instance method for the duration of a block.
  def stub_method(receiver, method_name, val_or_callable)
    singleton = receiver.singleton_class
    original = singleton.instance_method(method_name)
    implementation = val_or_callable.respond_to?(:call) ? val_or_callable : ->(*) { val_or_callable }
    receiver.define_singleton_method(method_name, &implementation)
    yield
  ensure
    singleton.send(:define_method, method_name, original) if original
  end
end

module ActiveSupport
  class TestCase
    include TestDataHelper

    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Add more helper methods to be used by all tests here...
  end
end
