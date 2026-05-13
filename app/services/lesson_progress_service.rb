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
    enrollment.update!(status: enrollment.overall_progress == 100 ? :completed : :in_progress)
  end
end
