# app/services/livekit_token_service.rb
class LivekitTokenService
  def self.generate(room_name:, identity:, name:, is_admin: false)
    token = LiveKit::AccessToken.new(
      api_key: ENV["LIVEKIT_API_KEY"],
      api_secret: ENV["LIVEKIT_API_SECRET"],
      identity: identity,
      name: name
    )

    token.video_grant = LiveKit::VideoGrant.new(
      roomJoin: true,
      room: room_name,
      canPublish: true,
      canSubscribe: true,
      roomAdmin: is_admin
    )

    token.to_jwt   # returns a JWT string
  end
end
