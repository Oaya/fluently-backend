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
  end
end
