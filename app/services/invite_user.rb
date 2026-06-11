class InviteUser
  def initialize(invited_by:, params:)
    @invited_by = invited_by
    @params = params
  end

  def call
    existing = User.find_by(email: @params[:email])

    if existing.present?
      return existing if existing.status == "active"

      SendInvitationEmailJob.perform_later(existing.id)
      return existing
    end

    invited_user = User.invite!(
      {
        email: @params[:email],
        first_name: @params[:first_name],
        last_name: @params[:last_name],
        role: @params[:role] || "student",
        status: "invited"
      },
      @invited_by,
      skip_invitation: true
    )

    return invited_user if invited_user.errors.any?

    invited_user.tap do |u|
      return u if u.errors.any?

      if @params[:role].to_s.downcase == "student" && @params[:courses].present?
        course_ids = @params[:courses].map { |c| c[:id] }

        course_ids.each do |course_id|
          course = Course.find(course_id)
          CreateEnrollment.new(user: invited_user, course: course).call
        end

        invited_user.invited_courses = Course.where(id: course_ids)
      end

      SendInvitationEmailJob.perform_later(invited_user.id)
      invited_user
    end
  end
end
