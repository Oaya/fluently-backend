class SeedEnrollmentLessonProgressJob < ApplicationJob
  queue_as :default

  def perform(enrollment_id)
    enrollment = Enrollment.find(enrollment_id)
    course = enrollment.course

    lessons = Lesson.joins(section: :course)
      .where(sections: { course_id: course.id })
      .order("sections.position, lessons.position")

    existing_lesson_ids = LessonProgress
      .where(enrollment_id: enrollment_id)
      .select(:lesson_id)
      .map(&:lesson_id)
      .to_set

    now = Time.current
    records = lessons.reject { |l| existing_lesson_ids.include?(l.id) }.map do |lesson|
      {
        enrollment_id: enrollment.id,
        lesson_id: lesson.id,
        status: "not_started",
        progress: 0,
        created_at: now,
        updated_at: now
      }
    end

    LessonProgress.insert_all(records) if records.any?

    first_lesson = lessons.first
    enrollment.update(last_accessed_lesson_id: first_lesson.id) if first_lesson
  end
end
