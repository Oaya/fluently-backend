require "test_helper"
include TestDataHelper

class EnrollmentTest < ActiveSupport::TestCase
  test "creates lesson progress for each course lesson when enrollment is created" do
    plan = create_plan
    tenant = create_tenant(plan: plan)
    user = create_user(tenant: tenant)
    course = create_course(tenant: tenant, title: "Seed course", description: "Course for progress seeding")
    section = create_section(tenant: tenant, course: course, title: "Part 1", description: "First part")
    lesson_one = create_lesson(tenant: tenant, section: section, title: "Lesson one", lesson_type: "reading")
    lesson_two = create_lesson(tenant: tenant, section: section, title: "Lesson two", lesson_type: "reading")

    enrollment = CreateEnrollment.new(tenant: tenant, user: user, course: course).call

    assert_equal 2, enrollment.lesson_progresses.count
    assert enrollment.lesson_progresses.exists?(lesson: lesson_one, status: "not_started", progress: 0)
    assert enrollment.lesson_progresses.exists?(lesson: lesson_two, status: "not_started", progress: 0)
  end
end
