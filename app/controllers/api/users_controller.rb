class Api::UsersController < ApplicationController
  before_action :authenticate_api_user!
  before_action :require_admin!, only: [ :index, :with_statues ]
  before_action :require_admin!, :require_active_subscription!, only: [ :destroy ]
  include Rails.application.routes.url_helpers

  # GET /api/users
  # This endpoint get students
  def index
    users = User.includes(:admin).filtering(filter_params).where.not(id: current_api_user.id)
    users = users.order(sort_params) if sort_params.present?

    render json: users.map { |user| user_result(user) }
  end

  # GET /api/users/with_statues
  # This endpoint get student with statues
  def with_statues
    users = User.where.not(id: current_api_user.id).includes(:admin, homeworks: :homework_submission).order(created_at: :asc)

    render json: users.map { |u| user_with_statues_result(u) }
  end

  # GET /api/users/:id
  def show
    user = User.find(params[:id])
    render json: user_result(user)
  end

  # PATCH /api/users/:id
  def update
    user = User.find(params[:id])

    if user.update(user_params)
      render json: user_result(user)
    else
      render_error(user.errors.full_messages, status: :unprocessable_entity)
    end
  end

  # DELETE /api/users/:id
  def destroy
    user = User.find(params[:id])
    user.destroy!

    head :no_content
  rescue ActiveRecord::RecordNotFound
    render_error("User not found", status: :not_found)
  end

  private

  def filter_params
    permitted = params.permit(:search, :status)

    role = params[:role]
    allowed_roles = %w[admin student]
    if role.present? && allowed_roles.include?(role)
      permitted[:role] = role
    end

    permitted
  end

  def sort_params
    allowed = %w[first_name email status role]
    priority_order = [ "status", "role", "first_name", "email" ]
    sort = params[:sort].to_s

    return nil if sort.blank?

    parts = sort.split(",")
    reordered = parts.sort_by do |part|
      field = part.delete_prefix("-")
      priority_order.index(field) || 999
    end

    clauses = reordered.map do |p|
      dir = p.start_with?("-") ? "DESC" : "ASC"
      field = p.delete_prefix("-")
      next unless allowed.include?(field)
      "#{field} #{dir}"
    end.compact

    clauses.join(", ")
  end

  def user_params
    params.require(:user).permit(
      :first_name,
      :last_name,
      :email,
      learning_languages: []
    )
  end

  def user_delete_params
    params.permit(user_ids: [])
  end

  def user_result(user)
    {
      id: user.id,
      first_name: user.first_name,
      last_name: user.last_name,
      email: user.email,
      status: User.statuses[user.status],
      created_at: user.created_at,
      avatar: user.avatar.attached? ? rails_blob_url(user.avatar, host: request.base_url) : nil,
      role: user.role,
      learning_languages: user.learning_languages
    }
  end

  def user_with_statues_result(user)
    {
      id: user.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name,
      role: user.role,
      created_at: user.created_at,
      status: User.statuses[user.status],
      avatar: user.avatar.attached? ? rails_blob_url(user.avatar, host: request.base_url) : nil,
      hw_status: homework_status_badge(user.homeworks)
    }
  end

  def homework_status_badge(homeworks)
    return nil if homeworks.empty?

    done_statuses = %w[submitted reviewed]
    today = Date.today

    pending = homeworks.reject { |hw|
      done_statuses.include?(hw.homework_submission&.status)
    }

    return "done" if pending.empty?

    overdue = pending.any? { |hw| hw.due_date.present? && hw.due_date.to_date < today }
    overdue ? "overdue" : "due"
  end
end
