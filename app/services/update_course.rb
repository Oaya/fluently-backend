class UpdateCourse
  def initialize(course:, params:)
    @course = course
    @course_data = params.except(:instructor_ids, :thumbnail_signed_id)
    @instructor_ids = params[:instructor_ids] || []
    @signed_id = params[:thumbnail_signed_id].to_s
    @has_thumb_key = params.key?(:thumbnail_signed_id)
  end

  def call
    ActiveRecord::Base.transaction do
      raise ActiveRecord::Rollback unless @course.update(@course_data)

      sync_instructors if @instructor_ids
      handle_thumbnail
    end

    @course
  end

  private

  def sync_instructors
    instructors = User.where(id: @instructor_ids)
    @course.course_instructors.where.not(instructor_id: @instructor_ids).destroy_all
    instructors.each { |i| CourseInstructor.find_or_create_by(course: @course, instructor: i) }
  end

  def handle_thumbnail
    return unless @has_thumb_key
    if @signed_id.present?
      @course.thumbnail.attach(@signed_id)
    else
      @course.thumbnail.purge if @course.thumbnail.attached?
    end
  end
end
