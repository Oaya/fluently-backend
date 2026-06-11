class CreateEnrollment
  def initialize(user:, course:)
    @user = user
    @course = course
  end

  def call
    Enrollment.transaction do
      Enrollment.find_or_create_by!(user: @user, course: @course) do |e|
        e.status = :enrolled
      end
    end
  end
end
