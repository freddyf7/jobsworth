class AgileMailer < ActionMailer::Base
  default :from => "freddyucab@gmail.com"

  def closed_story_mail(us)
    @user_story = us
    @url  = "http://example.com/login"
    mail(:to => "freddyucab@gmail.com", :subject => "Closed Story Notification")
  end
end
