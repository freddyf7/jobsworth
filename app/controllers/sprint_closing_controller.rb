class SprintClosingController < ApplicationController

  def closing

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

    if !params[:project_id].nil?
      project_id = params[:project_id]
      today_date = Date.today
      actual_iteration = Milestone.where("project_id = ? and due_at >= ? and init_date <= ?", project_id,today_date,today_date)
      iteration = actual_iteration[0]

      if iteration
        if iteration.due_at.to_date == today_date
          @finished_iteration = iteration
        else
          @finished_iteration = nil
        end

        next_iteration = Milestone.where("init_date >= ?",iteration.due_at).limit(1)
        @next_iteration = next_iteration[0]

        @remaining_us = Task.where("milestone_id = ? and status = 0",iteration.id)
        @closed_us = Task.where("milestone_id = ? and status = 1",iteration.id)

        #  generating data for burndown chart

        if !@finished_iteration.nil?

          @planned_points = 0

          @finished_iteration.tasks.each do |us|
            @planned_points = @planned_points + us.total_points
          end

          init_date = Date.civil(@finished_iteration.init_date.year,@finished_iteration.init_date.month,@finished_iteration.init_date.day)
          due_date = Date.civil(@finished_iteration.due_date.year,@finished_iteration.due_date.month,@finished_iteration.due_date.day)
          duration_days = (due_date - init_date).to_i

          @burndown_data = Array.new
          @closed_stories = Task.where("milestone_id = ? and status = 1",@finished_iteration.id)

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
              @closed_stories.each do |us|
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

          # Loading retrospectives
          @retrospective = Array.new
          project_iterations = Milestone.where("project_id = ?",params[:project_id])         

          project_iterations.each do |iter|
            retrospective = Restrospective.where("milestone_id = ?",iter.id)
            if !retrospective[0].nil?
               @retrospective << retrospective[0]
            end
          end

          if !@finished_iteration.nil?
            @actual_retrospective = Restrospective.find_by_milestone_id(@finished_iteration.id)
          end

        end

      end

    end

#    flash["notice"] = _('Retrospective:'+@actual_retrospective.observation)
  end

  def new_retrospective

    @retrospective = Restrospective.new
    @popup, @disable_title = true, true
    render :action => 'new_retrospective', :layout => false

    return

  end  

  def save_retrospective

    retro = Restrospective.new(params[:retrospective])
    if retro.save
      flash["notice"] = _('Retrospective was successfully saved.')
      redirect_to '/sprint_closing/closing?project_id='+params[:project_id]+'&tab=1'
    end

  end


  def view_retrospective

    @popup, @disable_title = true, true
    render :action => 'view_retrospective', :layout => false

    return
  end

  def update_retrospective

    observation = params[:retrospective_observation]

    retrospective_id = params[:retrospective_id]

    retrospective = Restrospective.find_by_id(retrospective_id)

    retrospective.observation = observation

    if retrospective.save!
       flash["notice"] = _('Retrospective was successfully updated.')
       redirect_to '/sprint_closing/closing?project_id='+params[:project_id]+'&tab=1'
    end
  end

  def edit_retrospective

    @popup, @disable_title = true, true
    render :action => 'edit_retrospective', :layout => false

    return
  end

  def load_retrospective
    iteration_id = params[:iteration_id]
    retrospective_id = params[:retrospective_id]

    @iteration = Milestone.find_by_id(iteration_id)
    @retrospective = Restrospective.find_by_id(retrospective_id)

    render :partial => 'sprint_closing/load_retrospective.json'

  end

  def move_stories

    stories = params[:story]
    values = params[:us]

    stories.each do |us_id|
        move_to = values[us_id]
        task = Task.find_by_id(us_id)
        task.milestone_id = move_to
        task.save!
    end

    redirect_to '/sprint_closing/closing?project_id='+params[:project_id]
    
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
    render :partial => 'sprint_closing/completed_stories'

  end

end
