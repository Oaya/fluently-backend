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

  def save_position(watched_seconds, duration_seconds)
    return if duration_seconds.nil? || duration_seconds <= 0

    # Never downgrade a completed lesson — only update resume position
    if @lesson_progress.completed?
      @lesson_progress.update!(watched_seconds: watched_seconds)
      return
    end

    pct = (watched_seconds.to_f / duration_seconds * 100).round.clamp(0, 100)

    if pct >= 90
      @lesson_progress.update!(status: :completed, progress: 100, watched_seconds: watched_seconds)
    else
      @lesson_progress.update!(status: :in_progress, progress: pct, watched_seconds: watched_seconds)
    end

    sync_enrollment_progress
  end

  private

  def sync_enrollment_progress
    enrollment = @lesson_progress.enrollment
    enrollment.update!(status: enrollment.overall_progress == 100 ? :completed : :in_progress)
  end
end
