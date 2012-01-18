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
      @closed_us = Array.new
      @open_us = Array.new

      iteration.tasks.each do |us|
        if us.status == 1
          @closed_us << us
        end
        if us.status == 0
          @open_us << us
        end
      end

    end
    render :partial => 'sprint_monitoring/completed_stories'

  end

end
