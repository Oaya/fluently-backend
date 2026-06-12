class UpdateCourse
  def initialize(course:, params:)
    @course = course
    @course_data = params.except(:thumbnail_signed_id)
    @signed_id = params[:thumbnail_signed_id].to_s
    @has_thumb_key = params.key?(:thumbnail_signed_id)
  end

  def call
    ActiveRecord::Base.transaction do
      raise ActiveRecord::Rollback unless @course.update(@course_data)

      handle_thumbnail
    end

    @course
  end

  private

  def handle_thumbnail
    return unless @has_thumb_key
    if @signed_id.present?
      @course.thumbnail.attach(@signed_id)
    else
      @course.thumbnail.purge if @course.thumbnail.attached?
    end
  end
end
