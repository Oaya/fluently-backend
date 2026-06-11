class CreateCourse
  def initialize(params:)
    @course_data = params.except(:instructor_ids, :thumbnail_signed_id)
    @instructor_ids = params[:instructor_ids] || []
    @signed_id = params[:thumbnail_signed_id].to_s
  end

  def call
    @course = Course.new(@course_data)
    @course.save

    instructors = sync_instructors
    handle_thumbnail

    return @course, instructors
  end

  private

  def sync_instructors
    instructors = User.where(id: @instructor_ids)
    instructors.each { |instructor| CourseInstructor.find_or_create_by(course: @course, instructor: instructor) }
    instructors
  end

  def handle_thumbnail
    @course.thumbnail.attach(@signed_id) if @signed_id.present?
  end
end
