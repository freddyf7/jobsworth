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

    if !params[:milestone_id].nil?
      milestone_id = params[:milestone_id]
      @milestone = Milestone.find_by_id(milestone_id)
      today_date = Date.today
      due_date = Date.civil(@milestone.due_date.year,@milestone.due_date.month,@milestone.due_date.day)
      @remaining_days = (due_date - today_date).to_i

      @closed_us = Array.new
      @open_us = Array.new

      @milestone.tasks.each do |us|
        if us.status == 1
          @closed_us << us
        end
        if us.status == 0
          @open_us << us
        end
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

      @burndown_data = Array.new
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

      @burndown_data = Array.new

      dias = Array.new
      for i in 0..duration_days
        dias << init_date + i
      end

      n = 1
      dias.each do |dia|
        @burndown_data[n] = dia
        @burndown_data[n+1] = 0
        @closed_us.each do |us|
          completed_at = us.completed_at.to_date
          if(completed_at == dia)
            @burndown_data[n+1] = @burndown_data[n+1] + us.total_points
          end
        end
        n = n + 2
      end

    end
    render :partial => 'sprint_monitoring/completed_stories'

  end

end
