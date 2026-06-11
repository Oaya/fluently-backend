class CreateLesson
  def initialize(params:, section:)
    @lesson_data = params.except(:video_signed_id)
    @signed_id = params[:video_signed_id].to_s
    @section = section
  end

  def call
    @lesson = @section.lessons.new(@lesson_data)
    @lesson.save
    handle_video

    @lesson
  end

  private

  def handle_video
    @lesson.video.attach(@signed_id) if @lesson.video? && @signed_id.present?
  end
end
