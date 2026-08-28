class InvoiceSerializer
  def initialize(invoice, host: nil)
    @invoice = invoice
    @host = host
  end

  def invoice_result
    {
      id: @invoice.id,
      amount: @invoice.amount,
      currency: @invoice.admin.currency,
      status: @invoice.status,
      due_date: @invoice.due_date,
      paid_at: @invoice.paid_at,
      notes: @invoice.notes,
      admin_id: @invoice.admin_id,
      created_at: @invoice.created_at,
      updated_at: @invoice.updated_at,
      student: {
        id: @invoice.student_id,
        first_name: @invoice.student.first_name,
        last_name: @invoice.student.last_name,
        avatar: UserSerializer.new(@invoice.student, host: @host).avatar_url
      },
      lesson: {
        id: @invoice.lesson_id,
        topic: @invoice.lesson.topic,
        scheduled_at: @invoice.lesson.scheduled_at,
        duration_in_minutes: @invoice.lesson.duration_in_minutes
      }
    }
  end
end
