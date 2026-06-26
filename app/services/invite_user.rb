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
        role: "student",
        status: "invited",
        admin_id: @invited_by.id,
        learning_languages: @params[:learning_languages],
        skip_invitation: true
      },
      @invited_by
    )

    return invited_user if invited_user.errors.any?

    invited_user.tap do |u|
      return u if u.errors.any?

      SendInvitationEmailJob.perform_later(u.id)
    end
  end
end
