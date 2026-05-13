class SeedLessonProgressJob < ApplicationJob
  queue_as :default

  def perform(lesson_id)
    lesson = Lesson.find(lesson_id)
    course = lesson.section.course
    return unless course.published?

    existing_enrollment_ids = LessonProgress
      .where(lesson_id: lesson_id)
      .select(:enrollment_id)
      .map(&:enrollment_id)
      .to_set

    now = Time.current
    records = course.enrollments
      .where.not(id: existing_enrollment_ids)
      .map do |enrollment|
        {
          enrollment_id: enrollment.id,
          lesson_id: lesson.id,
          tenant_id: enrollment.tenant_id,
          status: "not_started",
          progress: 0,
          created_at: now,
          updated_at: now
        }
      end

    LessonProgress.insert_all(records) if records.any?
  end
end
