class Api::UsersController < ApplicationController
  before_action :authenticate_api_user!
  before_action :require_admin!, only: [ :index ]
  before_action :require_admin!, :require_active_subscription!, only: [ :bulk_delete ]
  include Rails.application.routes.url_helpers

  # GET /api/users
  # This endpoint get students
  def index
    users = User.includes(:admin).filtering(filter_params).where.not(id: current_api_user.id)
    users = users.order(sort_params) if sort_params.present?

    render json: users.map { |user| user_result(user) }
  end

  # GET /api/users/:id
  def show
    user = User.find(params[:id])
    render json: user_result(user)
  end

  # DELETE /api/users/bulk_delete
  def bulk_delete
    user_ids = user_delete_params[:user_ids] || []
    unless user_ids.is_a?(Array)
      return render_error("user_ids must be an array", status: :bad_request)
    end

    users = User.where(id: user_ids).where.not(id: current_api_user.id)
    deleted_count = users.delete_all

    render json: { deleted_count: deleted_count }, status: :ok
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

  def user_delete_params
    params.permit(user_ids: [])
  end

  def user_result(user)
    {
      id: user.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name,
      role: user.role,
      created_at: user.created_at,
      status: User.statuses[user.status],
      avatar: user.avatar.attached? ? rails_blob_url(user.avatar, host: request.base_url) : nil,
      admin: user.admin.present? ? { id: user.admin.id, first_name: user.admin.first_name, last_name: user.admin.last_name, email: user.admin.email } : nil
    }
  end
end
