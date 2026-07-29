class DailyClient
  API_URL = "https://api.daily.co/v1"

  def create_room(name)
    HTTParty.post("#{API_URL}/rooms",
      headers: { "Authorization" => "Bearer #{api_key}" },
      body: { name: name }.to_json
    )
  end

  private

  def api_key
     ENV["DAILY_API_KEY"]
  end
end
