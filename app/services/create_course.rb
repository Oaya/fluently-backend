class CreateCourse
  def initialize(params:)
    @course_data = params.except(:thumbnail_signed_id)
    @signed_id = params[:thumbnail_signed_id].to_s
  end

  def call
    @course = Course.new(@course_data)
    @course.save
    handle_thumbnail

    @course
  end

  private

  def handle_thumbnail
    @course.thumbnail.attach(@signed_id) if @signed_id.present?
  end
end
