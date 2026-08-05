class Api::GoalsController < ApplicationController
  before_action :authenticate_api_user!
  before_action :require_admin!, only: [ :create, :update, :destroy ]
  before_action :set_goal, only: [ :show, :update, :destroy ]
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
    render json: goal_result(@goal), status: :ok
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

  def goal_result(goal)
    result = {
      id: goal.id,
      student_id: goal.student.id,
      title: goal.title,
      status: goal.status,
      progress: goal.progress,
      target_date: goal.target_date,
      created_at: goal.created_at,
      achieved_at: goal.achieved_at
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
