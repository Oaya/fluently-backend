class CreateEnrollment
    def initialize(user:, course:, tenant:)
      @user = user
      @course = course
      @tenant = tenant
    end

    def call
      Enrollment.transaction do
        enrollment = Enrollment.find_or_create_by!(
          user: @user,
          course: @course,
          tenant: @tenant
        ) do |e|
          e.status = :enrolled
        end

        SeedLessonProgressForEnrollment.new(enrollment).call

        enrollment
      end
    end
end
