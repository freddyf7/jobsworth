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
      @iteracion_actual = Milestone.where("due_at >= ? and project_id = ?",hoy,params[:project_id])
    end

    if !params[:milestone_id].nil?
      milestone_id = params[:milestone_id]
      @milestone = Milestone.find_by_id(milestone_id)
      today_date = Date.today
      due_date = Date.civil(@milestone.due_date.year,@milestone.due_date.month,@milestone.due_date.day)
      @remaining_days = (due_date - today_date).to_i

      @closed_us = Array.new
      @open_us = Array.new
      @planned_points = 0

      @milestone.tasks.each do |us|
        @planned_points = @planned_points + us.total_points
        if us.status == 1
          @closed_us << us
        end
        if us.status == 0
          @open_us << us
        end
      end

#     generating data for burndown chart

      milestone_id = params[:milestone_id]
      iteration = Milestone.find_by_id(milestone_id)

      init_date = Date.civil(iteration.init_date.year,iteration.init_date.month,iteration.init_date.day)
      due_date = Date.civil(iteration.due_date.year,iteration.due_date.month,iteration.due_date.day)
      duration_days = (due_date - init_date).to_i

      @burndown_data = Array.new
      @closed_us = Task.where("milestone_id = ? and status = 1",milestone_id)

      dias = Array.new
      for i in 0..duration_days
        dias << init_date + i
      end

      today = Date.today
      today = Date.civil(today.year,today.month,today.day)
      n = 0
      day = 1
      remaining_points = @planned_points
      dias.each do |dia|
        burned_today = 0
        @burndown_data[n] = day
        @burndown_data[n+1] = 0
        if (dia >= today)
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
      @iteracion_actual = Milestone.where("due_at >= ? and project_id = ?",hoy,params[:project_id])
      @user_stories = Task.where("milestone_id = ?", @iteracion_actual[0].id)

    end

  end


end
