class SprintClosingController < ApplicationController

  def closing

    if params[:project_id].nil?
      session[:id_prj] =-1
    else
      session[:id_prj] = params[:project_id]
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
      end

    end

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
    render :partial => 'sprint_monitoring/completed_stories'

  end

end
