class Api::CoursesController < ApplicationController
  before_action :authenticate_api_user!
  before_action :require_admin!, :require_active_subscription!, only: [ :create, :update, :destroy, :price, :publish ]
  include Rails.application.routes.url_helpers

  # GET /api/courses
  def index
    courses = Course.order(created_at: :desc)
    render json: courses.map { |course|
      course.as_json.merge(
        thumbnail: course.thumbnail.attached? ? rails_blob_url(course.thumbnail, host: request.base_url) : nil
      )
    }
  end

  # GET /api/courses/:id
  def show
    course = Course.includes(:instructors).find(params[:id])
    render json: course.as_json.merge(
      thumbnail: course.thumbnail.attached? ? rails_blob_url(course.thumbnail, host: request.base_url) : nil,
      level: Course.levels[course.level],
      category: Course.categories[course.category],
      instructors: course.instructors.map { |instructor|
        {
          id: instructor.id,
          email: instructor.email,
          first_name: instructor.first_name,
          last_name: instructor.last_name,
          avatar: instructor.avatar.attached? ? rails_blob_url(instructor.avatar, host: request.base_url) : nil
        }
      }
    )
  end

  # POST /api/courses
  def create
    course, instructors = CreateCourse.new(params: course_params.to_h).call
    course.reload

    if course.persisted? && course.errors.empty?
      render json: course_fetch_results(course, instructors), status: :created
    else
      render_error(course.errors.full_messages, status: :unprocessable_entity)
    end
  end

  # PATCH /api/courses/:id
  def update
    course = Course.find(params[:id])

    UpdateCourse.new(course: course, params: course_params.to_h).call
    course.reload

    if course.errors.empty?
      render json: course_fetch_results(course, course.instructors), status: :ok
    else
      render_error(course.errors.full_messages, status: :unprocessable_entity)
    end
  end

  # DELETE /api/courses/:id
  def destroy
    course = Course.find(params[:id])

    if course.destroy!
      render status: :ok
    else
      render_error(course.errors.full_messages, status: :unprocessable_entity)
    end
  end

  # GET /api/courses/:id/details
  def overview
    course = Course.includes(sections: :lessons, instructors: []).find(params[:id])

    render json: {
      id: course.id,
      title: course.title,
      description: course.description,
      level: Course.levels[course.level],
      category: Course.categories[course.category],
      thumbnail: course.thumbnail.attached? ? rails_blob_url(course.thumbnail, host: request.base_url) : nil,
      published: course.published,
      price: course.price,
      created_at: course.created_at,
      updated_at: course.updated_at,
      instructors: course.instructors.map { |instructor|
        {
          id: instructor.id,
          email: instructor.email,
          first_name: instructor.first_name,
          last_name: instructor.last_name,
          avatar: instructor.avatar.attached? ? rails_blob_url(instructor.avatar, host: request.base_url) : nil
        }
      },
      sections: course.sections.order(:position).map { |m|
        {
          id: m.id,
          title: m.title,
          description: m.description,
          position: m.position,
          lessons: m.lessons.order(:position).map { |l|
            {
              id: l.id,
              title: l.title,
              description: l.description,
              position: l.position,
              lesson_type: Lesson.lesson_types[l.lesson_type],
              duration_in_seconds: l.duration_in_seconds,
              video: l.video.attached? ? rails_blob_url(l.video, host: request.base_url) : nil,
              article: l.article
            }
          }
        }
      }
    }
  end

  # PATCH /api/courses/:id/price
  def price
    course = Course.find(params[:id])

    if course.update(price: params.require(:price))
      render json: course_fetch_results(course, course.instructors), status: :ok
    else
      render_error(course.errors.full_messages, status: :unprocessable_entity)
    end
  end

  # PATCH /api/courses/:id/publish
  def publish
    course = Course.find(params[:id])

    if course.update(published: true)
      render json: course, status: :ok
    else
      render_error(course.errors.full_messages, status: :unprocessable_entity)
    end
  end


  private

  def course_params
    params.permit(:title, :description, :category, :level, :thumbnail_signed_id, :published, instructor_ids: [])
  end

  def course_fetch_results(course, instructors)
    course.as_json.merge(
      thumbnail: course.thumbnail.attached? ? rails_blob_url(course.thumbnail, host: request.base_url) : nil,
      instructors: course.instructors.map { |instructor|
        {
          id: instructor.id,
          email: instructor.email,
          first_name: instructor.first_name,
          last_name: instructor.last_name,
          avatar: instructor.avatar.attached? ? rails_blob_url(instructor.avatar, host: request.base_url) : nil
        }
      }
    )
  end
end
