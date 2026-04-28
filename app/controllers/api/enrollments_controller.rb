class  Api::EnrollmentsController < ApplicationController
  before_action :authenticate_api_user!

  def start
    enrollment = Enrollment.find_by(id: params[:id], user: current_api_user)
    unless enrollment
      return render_error("Enrollment not found", status: :not_found)
    end
    SeedLessonProgressForEnrollment.new(enrollment).call
    enrollment.update(status: :in_progress)
  end
end
