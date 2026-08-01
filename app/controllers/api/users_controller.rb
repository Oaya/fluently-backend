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

    render json: users.map { |user| UserSerializer.new(user, host: request.base_url).user_result }
  end

  # GET /api/users/with_statues
  # This endpoint get student with statues
  def with_statues
    users = User.where.not(id: current_api_user.id).includes(:admin, homeworks: :homework_submission).order(created_at: :asc)

    render json: users.map { |u| UserSerializer.new(u, host: request.base_url).user_with_statues_result }
  end

  # GET /api/users/:id
  def show
    user = User.find(params[:id])
    render json: UserSerializer.new(user, host: request.base_url).user_result
  end

  # PATCH /api/users/:id
  def update
    user = User.find(params[:id])

    if user.update(user_params)
      render json: UserSerializer.new(user, host: request.base_url).user_result
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
      :status,
      :timezone,
      learning_languages: []
    )
  end

  def user_delete_params
    params.permit(user_ids: [])
  end
end
