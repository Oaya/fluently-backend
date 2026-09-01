class Api::UsersController < ApplicationController
  before_action :authenticate_api_user!
  before_action :require_admin!, only: [ :index, :with_statues, :destroy ]
  before_action :require_active_subscription!, only: [ :destroy ]
  before_action :set_user, only: [ :show, :update, :destroy ]
  include Rails.application.routes.url_helpers

  # GET /api/users
  # This endpoint get students
  def index
    users = User.includes(:admin).where.not(id: current_api_user.id).where(admin_id: current_api_user.id)


    render json: users.map { |user| UserSerializer.new(user, host: request.base_url).user_result }
  end

  # GET /api/users/with_statues
  # This endpoint get student with statues
  def with_statues
    users = User.where(admin_id: current_api_user.id).includes(:admin, homeworks: :homework_submission).order(created_at: :asc)

    render json: users.map { |u| UserSerializer.new(u, host: request.base_url).user_with_statues_result }
  end

  # GET /api/users/:id
  def show
    render json: UserSerializer.new(@user, host: request.base_url).user_result
  end

  # PATCH /api/users/:id
  def update
    pp user_params
    if @user.update(user_params)
      render json: UserSerializer.new(@user, host: request.base_url).user_result
    else
      render_error(@user.errors.full_messages, status: :unprocessable_entity)
    end
  end

  # DELETE /api/users/:id
  def destroy
    @user.destroy!

    head :no_content
  end

  private

  # Admins may access their own account and their own students'.
  # Students may only access their own account.
  def set_user
    scope = current_api_user.admin? ? User.where(id: current_api_user.id).or(User.where(admin_id: current_api_user.id)) : User.where(id: current_api_user.id)
    @user = scope.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_error("User not found", status: :not_found)
  end

  def filter_params
    permitted = params.permit(:search, :status)

    role = params[:role]
    allowed_roles = %w[admin student]
    if role.present? && allowed_roles.include?(role)
      permitted[:role] = role
    end

    permitted
  end

  def user_params
    params.require(:user).permit(
      :first_name,
      :last_name,
      :email,
      :status,
      :timezone,
      :lesson_rate,
      :currency,
      :cancellation_policy,
      language_levels: [ :language, :level ]
    )
  end

  def user_delete_params
    params.permit(user_ids: [])
  end
end
