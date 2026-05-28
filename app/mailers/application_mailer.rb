class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", ENV["MAILER_FROM"])
  layout "mailer"
end
