class Api::GoalsController < ApplicationController
  before_action :authenticate_api_user!
  before_action :require_admin!, only: [ :create, :update, :destroy ]
  before_action :set_goal, only: [ :show, :update, :destroy, :activity, :update_activity, :destroy_activity ]
  include Rails.application.routes.url_helpers

  # GET /api/goals
  # If the current_api_user is admin return the goals for their own students.
  # If students, then return their only goals
  def index
    goals = if current_api_user.admin?
      scope = current_api_user.goals_as_admin.includes(:student, :admin)
      params[:student_id].present? ? scope.where(student_id: params[:student_id]) : scope
    else
      current_api_user.goals_as_student.includes(:student, :admin)
    end

    goals = goals.order(created_at: :asc)

    render json: goals.map { |s| goal_result(s) }
  end

  # GET /api/goals/:id
  def show
    render json: goal_with_activities(@goal), status: :ok
  end

  # POST /api/goals
  def create
    student = current_api_user.students.find_by(id: goal_params[:student_id])
    return render_error("Student not found", status: :not_found) unless student

    goal = Goal.new(goal_params.merge(admin: current_api_user))

    if goal.save
      render json: goal_result(goal), status: :created
    else
      render_error(goal.errors.full_messages, status: :unprocessable_entity)
    end
  end

  # PATCH /api/goals/:id
  def update
    if goal_params[:student_id].present? && !current_api_user.students.exists?(id: goal_params[:student_id])
      return render_error("Student not found", status: :not_found)
    end

    if @goal.update(goal_params)
      render json: goal_result(@goal)
    else
      render_error(@goal.errors.full_messages, status: :unprocessable_entity)
    end
  end

  # DELETE /api/goals/:id
  def destroy
    @goal.destroy
    head :no_content
  end

  # POST /api/goals/:id/activity
  def activity
    return render_error("Only students can submit homework", status: :forbidden) if current_api_user.role == "admin"

    activity = @goal.goal_activities.new(
      admin_id: @goal.admin_id,
      student: current_api_user,
      date: goal_activity_params[:date],
      description: goal_activity_params[:description],
      progress: goal_activity_params[:progress]
    )

    ActiveRecord::Base.transaction do
      activity.save!
      @goal.update!(goal_activity_params.slice(:status, :progress, :achieved_at).to_h.compact)
    end


    render json: goal_with_activities(@goal), status: :created
  rescue ActiveRecord::RecordInvalid => e
    render_error(e.record.errors.full_messages, status: :unprocessable_entity)
  end

  # PATCH /api/goals/:id/activity
  def update_activity
    return render_error("Only students can submit homework", status: :forbidden) if current_api_user.role == "admin"

    activity = @goal.goal_activities.find(goal_activity_params[:activity_id])

    ActiveRecord::Base.transaction do
      activity.update!(goal_activity_params.slice(:date, :description, :progress).to_h.compact)
      @goal.update!(goal_activity_params.slice(:status, :progress, :achieved_at).to_h.compact)
    end

    render json: goal_with_activities(@goal), status: :ok
  rescue ActiveRecord::RecordNotFound
    render_error("activity not found", status: :not_found)
  rescue ActiveRecord::RecordInvalid => e
    render_error(e.record.errors.full_messages, status: :unprocessable_entity)
  end

  # DELETE /api/goals/:id/activity/:activity_id
  def destroy_activity
    activity = @goal.goal_activities.find(params[:activity_id])

    ActiveRecord::Base.transaction do
      activity.destroy!
      latest = @goal.goal_activities.order(date: :desc).first
      progress = latest&.progress || 0

      status = if progress == 100
        "achieved"
      elsif progress == 0
        "not_started"
      else
        "in_progress"
      end

      @goal.update!(progress: progress, status: status, achieved_at: progress == 100 ? @goal.achieved_at : nil)
    end

    head :no_content
  rescue ActiveRecord::RecordNotFound
    render_error("activity not found", status: :not_found)
  end


  private

  def set_goal
    scope = current_api_user.admin? ? current_api_user.goals_as_admin : current_api_user.goals_as_student
    @goal = scope.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_error("goal not found", status: :not_found)
  end

  def goal_params
    params.require(:goal).permit(
      :student_id, :title, :status, :description,
      :progress, :target_date, :achieved_at,
    )
  end

   def goal_activity_params
    params.permit(
      :activity_id, :date, :description,
      :progress, :status, :achieved_at
    )
   end

  def goal_result(goal)
    result = {
      id: goal.id,
      student_id: goal.student.id,
      title: goal.title,
      description: goal.description,
      status: goal.status,
      progress: goal.progress,
      target_date: goal.target_date,
      created_at: goal.created_at,
      achieved_at: goal.achieved_at
    }

    result
  end

  def goal_with_activities(goal)
    result = {
      id: goal.id,
      student_id: goal.student.id,
      title: goal.title,
      description: goal.description,
      status: goal.status,
      progress: goal.progress,
      target_date: goal.target_date,
      created_at: goal.created_at,
      achieved_at: goal.achieved_at,
      activities: goal.goal_activities.order(date: :desc).map { |a|
        {
          id: a.id,
          description: a.description,
          date: a.date,
          created_at: a.created_at,
          progress: a.progress
        }
      }
    }
    result
  end


  def homework_status_badge(homework)
    done_statuses = %w[submitted reviewed]

    return "submitted" if done_statuses.include?(homework.homework_submission&.status)

    overdue = homework.due_date.present? && homework.due_date.to_date < Date.today
    return "overdue" if overdue

    return "draft" if homework.homework_submission&.status == "draft"

    "pending"
  end
end
