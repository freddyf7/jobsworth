class SprintMonitoringController < ApplicationController

  def monitoring    

    if params[:project_id].nil?
      session[:id_prj] =-1
    else
      session[:id_prj] = params[:project_id]
    end

    if params[:milestone_id].nil?
      session[:id_milestone] =-1
    else
      session[:id_milestone] = params[:milestone_id]
    end

    if params[:user_id].nil?
      session[:user_id] =-1
    else
      session[:user_id] = params[:user_id]
    end
    
    if !params[:project_id].nil?
      hoy = Date.today
      @today_date = hoy.strftime("%d/%m/%Y")
      init_hoy = DateTime.new(hoy.year,hoy.month,hoy.day,23,59,59)
      finish_hoy = DateTime.new(hoy.year,hoy.month,hoy.day,0,0,1)
      iteracion_actual = Milestone.where("due_at >= ? and project_id = ? and init_date <= ?",finish_hoy,params[:project_id],init_hoy)
      @iteracion_actual = iteracion_actual[0]
    end

    if !@iteracion_actual.nil?
      today_date = Date.today
      due_date = Date.civil(@iteracion_actual.due_date.year,@iteracion_actual.due_date.month,@iteracion_actual.due_date.day)
      @remaining_days = (due_date - today_date).to_i

      @closed_us = Array.new
      @open_us = Array.new
      @planned_points = 0

      @iteracion_actual.tasks.each do |us|
        @planned_points = @planned_points + us.total_points
        if us.status == 1
          @closed_us << us
        end
        if us.status == 0
          @open_us << us
        end
      end

#     generating data for burndown chart

      milestone_id = @iteracion_actual.id
      iteration = Milestone.find_by_id(milestone_id)

      init_date = Date.civil(iteration.init_date.year,iteration.init_date.month,iteration.init_date.day)
      due_date = Date.civil(iteration.due_date.year,iteration.due_date.month,iteration.due_date.day)
      duration_days = (due_date - init_date).to_i

      @burndown_data = Array.new
      @closed_us = Task.where("milestone_id = ? and status = 1",milestone_id)
      @ideal_burndown = Array.new

      dias = Array.new
      for i in 0..duration_days
        dias << init_date + i
      end

      today = Date.today
      today = Date.civil(today.year,today.month,today.day)
      n = 2
      day = 1
      remaining_points = @planned_points

      ideal_remaining_points = @planned_points
      ideal_burning = (@planned_points.to_f / dias.size.to_f)

      @burndown_data[0] = 0
      @burndown_data[1] = @planned_points
      @ideal_burndown[0] = 0
      @ideal_burndown[1] = @planned_points

      dias.each do |dia|
        burned_today = 0
        @burndown_data[n] = day
        @burndown_data[n+1] = 0

        if (dia > today)
          @burndown_data[n+1]= -1
        else
        
        @closed_us.each do |us|
          completed_at = us.completed_at.to_date
            if(completed_at == dia)
              burned_today = burned_today + us.total_points
            end
        end
        
        @burndown_data[n+1] = remaining_points - burned_today
        end

        @ideal_burndown[n] = day
        ideal_remaining_points = ideal_remaining_points - ideal_burning

        if(ideal_remaining_points < 0 )
          @ideal_burndown[n+1] = (-1)*(ideal_remaining_points) + ideal_remaining_points
        else
          @ideal_burndown[n+1] = ideal_remaining_points
        end
        
        remaining_points = remaining_points - burned_today
        n = n + 2
        day = day + 1
      end


    end

  end

  def completed_stories

    if params[:milestone_id].to_i > 0

      milestone_id = params[:milestone_id]
      iteration = Milestone.find_by_id(milestone_id)

      init_date = Date.civil(iteration.init_date.year,iteration.init_date.month,iteration.init_date.day)
      due_date = Date.civil(iteration.due_date.year,iteration.due_date.month,iteration.due_date.day)
      duration_days = (due_date - init_date).to_i

      @closed_us = Array.new
      @open_us = Array.new
      @burned_points = 0
      @remaining_points = 0
      @added_value = 0
      @remaining_value = 0      

#      prueba = Date.new(2012,1,1)
#      if ( dias[0] == prueba)
#         @dias = 'JOJOJO'
#      end

#      iteracion = Milestone.find_by_id(8)
#      dia = Date.new(iteracion.init_date.year,iteracion.init_date.month,iteracion.init_date.day)



      iteration.tasks.each do |us|
        if us.status == 1
          @closed_us << us
          @burned_points = @burned_points + us.total_points
          @added_value = @added_value + us.business_value
        end
        if us.status == 0
          @open_us << us
          @remaining_points = @remaining_points + us.total_points
          @remaining_value = @remaining_value + us.business_value
        end
      end      

    end
    render :partial => 'sprint_monitoring/completed_stories'

  end

  def save_meeting

    @meeting = Meeting.new(params[:meeting])    
    if @meeting.save
      flash["notice"] = _('Meeting was successfully saved.')
      redirect_to '/sprint_monitoring/monitoring'
    end

  end

  def load_meeting

    @meeting = Meeting.new
    meeting_day = params[:meeting_day]
    developer = params[:developer_id]
    fecha = Date.strptime(meeting_day, "%d/%m/%Y")

    meetings = Meeting.where('day= ? and user_id = ?',fecha,developer)

    @meeting = meetings[0]

    if @meeting.nil?
      @meeting = Meeting.new
      @meeting.done = '-1'
      @meeting.to_do = '-1'
      @meeting.observation = '-1'
      @iteration_meeting = '-1'
    else
      @iteration_meeting = Milestone.find_by_id(@meeting.milestone_id)
    end

    render :partial => 'sprint_monitoring/selected_meeting'    
  end


  def taskboard
    
    if params[:project_id].nil?
      session[:id_prj] =-1
    else
      session[:id_prj] = params[:project_id]
    end

    if !params[:project_id].nil?
      hoy = Date.today
      init_hoy = DateTime.new(hoy.year,hoy.month,hoy.day,23,59,59)
      finish_hoy = DateTime.new(hoy.year,hoy.month,hoy.day,0,0,1)
      @iteracion_actual = Milestone.where("due_at >= ? and project_id = ? and init_date <= ?",finish_hoy,params[:project_id],init_hoy)
      if !@iteracion_actual[0].nil?
        @user_stories = Task.where("milestone_id = ?", @iteracion_actual[0].id)
      end
    end

  end

  def save_taskboard

    #verificando cambios de status en las tareas de las historias y guardandolas

    changed_activities = Array.new

    if params[:todo_tasks]
      params[:todo_tasks].each do |act|
        activity = StoryActivity.find_by_id(act.to_i)
        old_status_to_do = activity.status
          if old_status_to_do != 'to_do'
            activity.status = 'to_do'
            activity.save!
            changed_activities << activity
            changed_activities << old_status_to_do
            changed_activities << 'to_do'
          end
      end
    end

    if params[:progress_tasks]
      params[:progress_tasks].each do |act|
        activity = StoryActivity.find_by_id(act.to_i)
        old_status_progress = activity.status
          if old_status_progress != 'progress'
            activity.status = 'progress'
            activity.save!
            changed_activities << activity
            changed_activities << old_status_progress
            changed_activities << 'progress'
          end

      end
    end

    if params[:verify_tasks]
      params[:verify_tasks].each do |act|
        activity = StoryActivity.find_by_id(act.to_i)
        old_status_verify = activity.status
          if old_status_verify != 'verify'
            activity.status = 'verify'
            activity.save!
            changed_activities << activity
            changed_activities << old_status_verify
            changed_activities << 'verify'            
          end
      end
    end

    if params[:done_tasks]
      params[:done_tasks].each do |act|
        activity = StoryActivity.find_by_id(act.to_i)
        old_status_done = activity.status
          if old_status_done != 'done'
            activity.status = 'done'
            activity.save!
            changed_activities << activity
            changed_activities << old_status_done
            changed_activities << 'done'            
          end
      end
    end

    #las tareas que tuvieron cambios de status generan un email

    n = 0
    while n <= changed_activities.size-1 do
      activity = changed_activities[n]
      previous_status = changed_activities[n+1]
      new_status = changed_activities[n+2]
      us = Task.find_by_id(activity.task_id)
      AgileMailer.changed_activity_mail(activity,previous_status,new_status,us).deliver
      n=n+3
    end


    # si todas las tareas estan 'done' se cierra la historia

    iteration_id = params[:current_iteration]
    stories = Task.where('milestone_id = ?',iteration_id)

    stories.each do |us|
      activities = StoryActivity.where('task_id = ?',us.id)
      if activities.size > 0
        done_activities = StoryActivity.where("task_id = ? and status = 'done'",us.id)
          if activities.size == done_activities.size
            if us.status == 0
              us.status = 1
              us.completed_at = Time.now.utc
              if us.save!
                taskuser = TaskUser.find_by_task_id(us.id)
                user = User.find_by_id(taskuser.user_id)
                AgileMailer.closed_story_mail(us,user).deliver
              end
            end
          else
            if us.status == 1
              us.status = 0
              us.completed_at = nil
              if us.save!
                taskuser = TaskUser.find_by_task_id(us.id)
                user = User.find_by_id(taskuser.user_id)
                AgileMailer.reopened_story_mail(us,user).deliver
              end
            end
          end
      end
    end

    #asignacion de developer a la historia

#    if params[:developer].size > 0
    if params[:developer]
      developer = params[:developer]
      story = params[:us_dev]
      
      for i in 0..params[:developer].size-1
        if(developer[i].to_i > 0)
          user = User.find_by_id(developer[i])
          us = Task.find_by_id(story[i])
          task_user = TaskUser.new
          task_user.task_id = story[i]
          task_user.user_id = developer[i]
          task_user.type = 'TaskOwner'
          task_user.unread = 0
          if task_user.save!
            AgileMailer.assigned_story_mail(user,us).deliver
          end
        end
      end
    end

    flash["notice"] = _('Changes were successfully saved.')
    redirect_to '/sprint_monitoring/taskboard?project_id='+params[:project_id]
  end

  def new_activity

    @activity = StoryActivity.new
    @popup, @disable_title = true, true
    render :action => 'new_activity', :layout => false

    return

  end

  def save_activity

    @activity = StoryActivity.new(params[:story_activity])
    @activity.status = "to_do"
    us = Task.find_by_id(@activity.task_id)

    if @activity.save
      AgileMailer.new_activity_mail(us,@activity).deliver

      flash["notice"] = _('Activity was successfully saved.')
      redirect_to '/sprint_monitoring/taskboard?project_id='+params[:project_id]
    end

  end

  def edit_activity
    
    @popup, @disable_title = true, true
    render :action => 'edit_activity', :layout => false

    return

  end

  def load_activity
    activity_id = params[:activity_id]
    activity = StoryActivity.find_by_id(activity_id)
    @activity_name = activity.name
    @activity_description = activity.description
    @activity_developer = activity.user_id

    render :partial => 'sprint_monitoring/selected_activity.json'
  end

  def update_activity
    activity_id = params[:activity_id]
    activity = StoryActivity.find_by_id(activity_id)

    activity.name = params[:activity_name]
    activity.description = params[:activity_description]
    activity.user_id = params[:activity_developer]

    if activity.save!
      flash["notice"] = _('Activity was successfully updated.')
      redirect_to '/sprint_monitoring/taskboard?project_id='+params[:project_id]
    end
  end


end
