class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "ayaaa.okzk+no_reply@gmail.com")
  layout "mailer"
end
