class UpdateLesson
  def initialize(lesson:, params:)
    @lesson = lesson
    @lesson_data = params.except(:video_signed_id)
    @signed_id = params[:video_signed_id].to_s
    @has_video_key = params.key?(:video_signed_id)
  end

  def call
    ActiveRecord::Base.transaction do
      raise ActiveRecord::Rollback unless @lesson.update(@lesson_data)


      handle_video
    end

    @lesson
  end

  private

  def handle_video
    return unless @lesson.video? && @has_video_key
    if @signed_id.present?
      @lesson.video.attach(@signed_id)
    else
      @lesson.video.purge if @lesson.video.attached?
    end
  end
end
