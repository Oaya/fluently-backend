class InviteUser
  def initialize(tenant:, invited_by:, params:)
    @tenant = tenant
    @invited_by = invited_by
    @params = params
  end

  def call
      admin_limit_error! if @params[:role].to_s.downcase == "admin"

      existing = User.find_by(email: @params[:email])

      if existing.present?
        # If the user already exists and active, don't resend the invitation email
        if existing.status == "active"
          return existing
        end
        # If the user exists but is not active, we can resend the invitation email by calling invite! again
        existing.deliver_invitation
        return existing
      end

      invited_user = User.invite!(
        {
          email: @params[:email],
          first_name: @params[:first_name],
          last_name: @params[:last_name],
          tenant_id: @tenant.id,
          status: "invited"
        },
        @invited_by,
        skip_invitation: true
      )

      return invited_user if invited_user.errors.any?

      invited_user.tap do |u|
        # If invite failed, let controller handle errors
        return u if u.errors.any?

        # Create membership for invited user
        Membership.find_or_create_by!(
          user: invited_user,
          tenant_id: @tenant.id,
          role: @params[:role]
        )

        # If the user role is student then create enrolment
        if @params[:role].to_s.downcase == "student" && @params[:courses].present?
          course_ids = @params[:courses].map { |c| c[:id] }

          course_ids.each do |course_id|
            Enrollment.find_or_create_by!(
              user: invited_user,
              course_id: course_id,
              tenant: @tenant
            )
          end

          invited_user.invited_courses = Course.where(id: course_ids)
        end

        # Send invitation now after created Member
        invited_user.deliver_invitation
        invited_user
      end
  end

  private

  def admin_limit_error!
    max = @tenant.plan.features["max_admin"]

    user = User.find_by(email: @params[:email])

    count = @tenant.memberships.where(role: "admin").count

    return if count < max || user&.membership&.role.to_s.downcase == "admin"

    raise StandardError, "Your plan allows only #{max} admin memberships"
  end
end
