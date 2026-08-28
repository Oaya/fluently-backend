class Api::InvoicesController < ApplicationController
  before_action :authenticate_api_user!
  before_action :require_admin!, :require_pro_plan!, except: [ :show ]
  before_action :set_invoice, only: [ :update, :destroy, :show ]

  # GET /api/invoices
  def index
    invoices = if current_api_user.admin?
      scope = current_api_user.invoices_as_admin.includes(:student, :lesson)
      params[:student_id].present? ? scope.where(student_id: params[:student_id]) : scope
    else
      current_api_user.invoices_as_student.includes(:student, :admin)
    end

    render json: invoices.order(created_at: :desc).map { |i| InvoiceSerializer.new(i, host: request.base_url).invoice_result }
  end

  # GET /api/invoices/:id
  def show
    render json: InvoiceSerializer.new(@invoice, host: request.base_url).invoice_result
  end

  # POST /api/invoices
  def create
    lesson = current_api_user.lessons_as_admin.find_by(id: invoice_params[:lesson_id])
    return render_error("Lesson not found", status: :not_found) unless lesson

    invoice = Invoice.new(invoice_params.merge(admin: current_api_user, student_id: lesson.student_id))

    if invoice.save
      render json: InvoiceSerializer.new(invoice, host: request.base_url).invoice_result, status: :created
    else
      render_error(invoice.errors.full_messages, status: :unprocessable_entity)
    end
  end

  # PATCH /api/invoices/:id
  def update
    if @invoice.update(invoice_params)
      render json: InvoiceSerializer.new(@invoice, host: request.base_url).invoice_result
    else
      render_error(@invoice.errors.full_messages, status: :unprocessable_entity)
    end
  end

  # DELETE /api/invoices/:id
  def destroy
    @invoice.destroy
    head :no_content
  end

  private

  def set_invoice
    @invoice = if current_api_user.admin?
      current_api_user.invoices_as_admin.find(params[:id])
    else
      current_api_user.invoices.find(params[:id])
    end
  rescue ActiveRecord::RecordNotFound
    render_error("Invoice not found", status: :not_found)
  end

  def invoice_params
    params.require(:invoice).permit(:lesson_id, :amount, :status, :due_date, :notes, :paid_at)
  end
end
