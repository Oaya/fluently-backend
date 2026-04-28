class SeedLessonProgressForEnrollment
  def initialize(enrollment)
    @enrollment = enrollment
  end

  def call
    @enrollment.course.sections
      .order(:position)
      .includes(:lessons)
      .each do |section|
      section.lessons.order(:position).each do |lesson|
        LessonProgress.find_or_create_by!(
          enrollment: @enrollment,
          lesson: lesson
        ) do |progress|
          progress.tenant = @enrollment.tenant
          progress.status = :not_started
          progress.progress = 0
        end
      end
    end

    # set the enrollment of the last_accessed_lesson to the first lesson of the course
    first_lesson = @enrollment.course.sections.order(:position).first.lessons.order(:position).first
    @enrollment.update(last_accessed_lesson_id: first_lesson.id) if first_lesson
  end
end
