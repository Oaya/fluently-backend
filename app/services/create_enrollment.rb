class CreateEnrollment
  def initialize(user:, level:)
    @user = user
    @level = level
  end

  def call
    Enrollment.transaction do
      Enrollment.find_or_create_by!(user: @user) do |e|
        e.status = :enrolled
        e.level = @level
      end
    end
  end
end
