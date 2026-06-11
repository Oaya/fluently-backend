class Api::LessonsController < ApplicationController
  before_action :authenticate_api_user!
  before_action :require_admin!, :require_active_subscription!, only: [ :create, :update, :destroy ]
  include Rails.application.routes.url_helpers

  # GET /api/sections/:section_id/lessons
  def index
    section = Section.find(params[:section_id])
    lessons = section.lessons.order(:position)
    render json: lessons.map { |lesson|
      lesson.as_json.merge(
        video: lesson.video.attached? ? rails_blob_url(lesson.video, host: request.base_url) : nil
      )
    }
  end

  # GET /api/lessons/:id
  def show
    lesson = Lesson.find(params[:id])
    render json: lesson_fetch_results(lesson)
  end

  # POST /api/sections/:section_id/lessons
  def create
    section = Section.find(params[:section_id])

    lesson = CreateLesson.new(
      params: lesson_params.to_h,
      section: section
    ).call

    lesson.reload

    if lesson.persisted? && lesson.errors.empty?
      render json: lesson_fetch_results(lesson), status: :created
    else
      render_error(lesson.errors.full_messages, status: :unprocessable_entity)
    end
  end

  # PATCH /api/lessons/:id
  def update
    lesson = Lesson.find(params[:id])
    UpdateLesson.new(lesson: lesson, params: lesson_params.to_h).call

    lesson.reload

    if lesson.errors.empty?
      render json: lesson_fetch_results(lesson), status: :ok
    else
      render_error(lesson.errors.full_messages, status: :unprocessable_entity)
    end
  end

  # DELETE /api/lessons/:id
  def destroy
    lesson = Lesson.find(params[:id])

    if lesson.destroy!
      render status: :ok
    else
      render_error(lesson.errors.full_messages, status: :unprocessable_entity)
    end
  end

  def reorder
    section = Section.find(params[:section_id])
    ordered_ids = params.require(:lesson_ids)

    ActiveRecord::Base.transaction do
      section.lessons.update_all("position = position + 1000000")
      ordered_ids.each_with_index do |lesson_id, index|
        section.lessons.where(id: lesson_id).update_all(position: index + 1)
      end
    end
  end


  private

  def lesson_params
    params.permit(:title, :description, :duration_in_seconds, :lesson_type, :video_signed_id, :article)
  end

  def lesson_fetch_results(lesson)
    lesson.as_json.merge(
      video: lesson.video.attached? ? rails_blob_url(lesson.video, host: request.base_url) : nil
    )
  end
end
