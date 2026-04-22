require "test_helper"
include TestDataHelper

class LessonProgressTest < ActiveSupport::TestCase
  setup do
    @plan = create_plan

    @tenant = create_tenant(plan: @plan)

    @course = Course.create!(tenant: @tenant, title: "Test Course", description: "Test Course Description")

    @section = Section.create!(
      tenant: @tenant,
      course: @course,
      title: "Section A",
      description: "Section A Description"
    )

    @user = User.create!(
      email: "lesson-progress-#{SecureRandom.hex(4)}@example.com",
      first_name: "Test",
      last_name: "Student",
      tenant: @tenant,
      status: "active",
      password: "password123",
      password_confirmation: "password123",
      confirmed_at: Time.current
    )

    @lesson = Lesson.create!(
      tenant: @tenant,
      section: @section,
      title: "Lesson A",
      lesson_type: "reading"
    )

    @enrollment = CreateEnrollment.new(
      tenant: @tenant,
      user: @user,
      course: @course
    ).call

    @enrollment.reload
    @lesson_progress = @enrollment.lesson_progresses.find_by!(lesson: @lesson)
  end

  test "lesson_id uniqueness is scoped to enrollment" do
    duplicate = LessonProgress.new(
      enrollment: @lesson_progress.enrollment,
      lesson: @lesson_progress.lesson,
      tenant: @tenant
    )

    assert_raises(ActiveRecord::RecordNotUnique) do
      duplicate.save!(validate: false)
    end
  end

  test "same lesson can belong to different enrollments" do
    other_user = User.create!(
      email: "lesson-progress-other-#{SecureRandom.hex(4)}@example.com",
      first_name: "Other",
      last_name: "Student",
      tenant: @tenant,
      status: "active",
      password: "password123",
      password_confirmation: "password123",
      confirmed_at: Time.current
    )
    other_enrollment = CreateEnrollment.new(tenant: @tenant, user: other_user, course: @course).call

    enrollment_ids = LessonProgress.where(lesson: @lesson).pluck(:enrollment_id)
    assert_equal 2, enrollment_ids.uniq.size
    assert_includes enrollment_ids, @enrollment.id
    assert_includes enrollment_ids, other_enrollment.id
  end

  test "status can move through workflow values" do
    @lesson_progress.update!(status: :in_progress, progress: 40)
    assert_predicate @lesson_progress, :in_progress?
    assert_equal 40, @lesson_progress.progress

    @lesson_progress.update!(status: :completed, progress: 100)
    assert_predicate @lesson_progress, :completed?
    assert_equal 100, @lesson_progress.reload.progress
  end
end
