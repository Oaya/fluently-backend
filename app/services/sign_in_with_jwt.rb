class SignInWithJwt
  include Rails.application.routes.url_helpers
  # Store controller instance so we can access helpers like `resource_name`
  def initialize(controller)
    @controller = controller
  end

  # Issues a JWT for a user and returns a payload for the frontend
  def issue_jwt(user,  message: nil)
    # Generate a JWT for this user WITHOUT using sessions
    # This returns an array: [token, payload] just get the token
    jwt, _payload = Warden::JWTAuth::UserEncoder.new.call(user, :api_user, nil)



    # Safety check: if token generation failed, raise immediately
    raise "Could not generate authentication token" if jwt.blank?

    {
      message: message,
      token: jwt,
      user: UserSerializer.new(user, host: @controller.request.base_url).user_result
    }
  end

  private

  # Always use the Devise mapping scope your app uses (:api_user)
  def detect_scope
    if @controller.respond_to?(:resource_name, true)
      @controller.send(:resource_name) # should be :api_user in your app
    else
      :api_user
    end
  end
end
