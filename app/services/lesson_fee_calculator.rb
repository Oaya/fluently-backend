class LessonFeeCalculator
  # Sets/clears the fee when a lesson transitions into or out of "no_show".
  def no_show_fee_attrs(lesson, new_status)
    if new_status == "no_show" && lesson.status != "no_show"
      student = lesson.student
      admin = lesson.admin
      return {} unless student.lesson_rate.present? && admin.no_show_fee_percent.to_i > 0

      {
        cancellation_fee_amount: (student.lesson_rate * admin.no_show_fee_percent / 100.0).round(2)
      }
    elsif lesson.status == "no_show" && new_status.present? && new_status != "no_show"
      { cancellation_fee_amount: nil }
    else
      {}
    end
  end

  # Fee for a student cancelling within the admin's late-cancellation window.
  def late_cancellation_fee_attrs(lesson)
    admin = lesson.admin
    student = lesson.student
    return {} unless admin.cancellation_window_hours.to_i > 0 && student.lesson_rate.present?

    hours_until = (lesson.scheduled_at - Time.current) / 3600.0
    return {} unless hours_until < admin.cancellation_window_hours

    {
      cancellation_fee_amount: (student.lesson_rate * admin.late_cancellation_fee_percent.to_f / 100.0).round(2)
    }
  end
end
