class AgileMailer < ActionMailer::Base
  default :from => "asgard.agileclockingit@gmail.com"

  def closed_story_mail(us,user,project)
    @project = project
    @user_story = us
    @user = user
    mail(:to => "asgard.ti@grupoasgard.com.ve", :subject => "Historia de usuario cerrada")
  end

  def reopened_story_mail(us,user,project)
    @project = project
    @user_story = us
    @user = user
    mail(:to => "asgard.ti@grupoasgard.com.ve", :subject => "Historia de usuario Re-abierta")
  end

  def changed_activity_mail(activity, previous_status, new_status,us,project)
    @project = project
    @activity= activity
    @previous_status= previous_status
    @new_status= new_status
    @us = us

    if (new_status == 'verify')
      mail(:to => "asgard.ti@grupoasgard.com.ve", :subject => "Tarea por verificar")
    else
      mail(:to => "asgard.ti@grupoasgard.com.ve", :subject => "Notificacion de avance")
    end
    
  end

  def new_activity_mail(us,activity,project)
    @project = project
    @activity= activity
    @us = us
    mail(:to => "asgard.ti@grupoasgard.com.ve", :subject => "Nueva tarea agregada")
  end

  def assigned_story_mail(user,us,project)
    @project = project
    @us = us
    @user = user
    mail(:to => "asgard.ti@grupoasgard.com.ve", :subject => "Historia de usuario asignada")
  end

  def edited_activity_mail(user,us,activity,project)
    @project = project
    @us = us
    @user = user
    @activity= activity
    mail(:to => "asgard.ti@grupoasgard.com.ve", :subject => "Tarea ha sido editada.")
  end

end
