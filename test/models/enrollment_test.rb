require "test_helper"
include TestDataHelper

class EnrollmentTest < ActiveSupport::TestCase
  test "creates enrollment with enrolled status for a user and course" do
    plan = create_plan
    tenant = create_tenant(plan: plan)
    user = create_user(tenant: tenant)
    course = create_course(tenant: tenant, title: "Seed course", description: "Course for progress seeding")

    enrollment = CreateEnrollment.new(tenant: tenant, user: user, course: course).call

    assert_equal "enrolled", enrollment.status
    assert_equal user, enrollment.user
    assert_equal course, enrollment.course
    assert_equal tenant, enrollment.tenant
  end

  test "does not create duplicate enrollment for the same user and course" do
    plan = create_plan
    tenant = create_tenant(plan: plan)
    user = create_user(tenant: tenant)
    course = create_course(tenant: tenant, title: "Seed course", description: "Course for progress seeding")

    CreateEnrollment.new(tenant: tenant, user: user, course: course).call

    assert_no_difference "Enrollment.count" do
      CreateEnrollment.new(tenant: tenant, user: user, course: course).call
    end
  end
end
