Mailjet.configure do |config|
  config.api_key = ENV["MAILJET_API_KEY"]
  config.secret_key = ENV["MAILJET_SECRET_KEY"]
  config.default_from = ENV.fetch("MAILER_FROM", "ayaaa.okzk@gmail.com")
end
