class Api::SectionsController < ApplicationController
  before_action :authenticate_api_user!
  before_action :require_admin!, :require_active_subscription!, only: [ :create, :update, :destroy ]

  # GET /api/courses/:course_id/sections
  def index
    course = Course.find(params[:course_id])
    sections = course.sections.order(:position)

    render json: sections
  end

  # GET /api/sections/:id
  def show
    section = Section.find(params[:id])
    render json: section
  end

  # POST /api/courses/:course_id/sections
  def create
    course = Course.find(params[:course_id])
    section = course.sections.new(section_params)

    if section.save!
      render json: section, status: :created
    else
      render_error(section.errors.full_messages, status: :unprocessable_entity)
    end
  end

  # PATCH /api/sections/:id
  def update
    section = Section.find(params[:id])

    if section.update(section_params)
      render json: section, status: :created
    else
      render_error(section.errors.full_messages, status: :unprocessable_entity)
    end
  end

  # DELETE /api/sections/:id
  def destroy
    section = Section.find(params[:id])

    if section.destroy!
      render status: :ok
    else
      render_error(section.errors.full_messages, status: :unprocessable_entity)
    end
  end

  def reorder
    course = Course.find(params[:course_id])
    ordered_ids = params.require(:section_ids)

    ActiveRecord::Base.transaction do
      course.sections.update_all("position = position + 1000000")
      ordered_ids.each_with_index do |section_id, index|
        course.sections.where(id: section_id).update_all(position: index + 1)
      end
    end
  end


  private

  def section_params
    params.permit(:title, :description, :position)
  end
end
