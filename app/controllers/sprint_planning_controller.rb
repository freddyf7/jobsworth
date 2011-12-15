class SprintPlanningController < ApplicationController

  def planning
    respond_to do |format|
      format.html  # planning.html.erb
#     format.json  { render :json => @posts }
    end
  end

end
