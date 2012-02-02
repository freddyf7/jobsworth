class AgileMailer < ActionMailer::Base
  default :from => "freddyucab@gmail.com"

  def closed_story_mail(us,user)
    @user_story = us
    @user = user
    mail(:to => "freddyucab@gmail.com", :subject => "Historia de usuario cerrada")
  end

  def reopened_story_mail(us,user)
    @user_story = us
    @user = user
    mail(:to => "freddyucab@gmail.com", :subject => "Historia de usuario Re-abierta")
  end

  def changed_activity_mail(activity, previous_status, new_status,us)
    @activity= activity
    @previous_status= previous_status
    @new_status= new_status
    @us = us

    if (new_status == 'verify')
      mail(:to => "freddyucab@gmail.com", :subject => "Tarea por verificar")
    else
      mail(:to => "freddyucab@gmail.com", :subject => "Notificacion de avance")
    end
    
  end

  def new_activity_mail(us,activity)
    @activity= activity
    @us = us
    mail(:to => "freddyucab@gmail.com", :subject => "Nueva tarea agregada")
  end

  def assigned_story_mail(user,us)
    @us = us
    @user = user
    mail(:to => "freddyucab@gmail.com", :subject => "Historia de usuario asignada")
  end

end
