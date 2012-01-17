class SprintMonitoringController < ApplicationController

  def monitoring

    if params[:project_id].nil?
      session[:id_prj] =-1
    else
      session[:id_prj] = params[:project_id]
      @project = Project.find_by_id(params[:project_id])
    end
    
  end

end
