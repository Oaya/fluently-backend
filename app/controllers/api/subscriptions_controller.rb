class Api::SubscriptionsController < ApplicationController
  before_action :authenticate_api_user!, :require_admin!, :set_current_user

  # GET /api/subscriptions/payment_checkout
  def payment_checkout
    plan = Plan.find_by(name: params[:plan])
    payload = Subscriptions.new.checkout_session(plan, current_api_user)
    render json: payload, status: :ok
  end

  # POST /api/subscription/cancel
  def cancel
    payload = Subscriptions.new.cancel_subscription(current_api_user)
    render json: payload, status: :ok
  end

  # POST /api/subscription/change_plan
  def change_plan
    new_plan = Plan.find_by(name: params[:plan])
    unless new_plan
      return render_error("Invalid plan: #{params[:plan]}", status: :unprocessable_entity)
    end
    payload = Subscriptions.new.change_plan(current_api_user, new_plan)
    render json: payload, status: :ok
  end
end
