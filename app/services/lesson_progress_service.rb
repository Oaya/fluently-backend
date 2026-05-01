class LessonProgressService
  def initialize(lesson_progress)
    @lesson_progress = lesson_progress
  end

  def complete
    @lesson_progress.update!(status: :completed, progress: 100)
    sync_enrollment_progress
  end

  def incomplete
    @lesson_progress.update!(status: :not_started)
    sync_enrollment_progress
  end

  private

  def sync_enrollment_progress
    enrollment = @lesson_progress.enrollment
    total = Lesson.joins(section: :course).where(sections: { course_id: enrollment.course_id }).count
    completed = enrollment.lesson_progresses.where(status: :completed).count
    overall_progress = total > 0 ? (completed.to_f / total * 100).round : 0

    enrollment.update!(
      overall_progress: overall_progress,
      status: overall_progress == 100 ? :completed : :in_progress
    )
  end
end
