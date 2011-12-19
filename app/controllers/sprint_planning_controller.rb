class SprintPlanningController < ApplicationController

  def planning
    @project = Project.new(params[:project])

    #para que el combobox de proyecto cargue con un proyecto
    if (params[:project_id].nil? or params[:project_id] == 0)
#      backlog_project = current_user.projects.find :first
      backlog_project = current_task_filter.tasks[0].project.id
      session[:id_prj] = backlog_project
    else
      session[:id_prj] = params[:project_id]
    end

    @tasks = tasks_for_list

    respond_to do |format|
      format.html { render :action => "planning_backlog_grid" }
      format.json { render :template => "tasks/backlog_list.json"}
    end


#    respond_to do |format|
#      format.html  # planning.html.erb
##     format.json  { render :json => @posts }
#    end
  end

  def auto_complete_for_milestone_project_name
    text = params[:term]
    if !text.blank?
      @projects = current_user.company.projects.where("lower(name) like ?", "%#{ text }%")
    end
    render :json=> @projects.collect{|project| {:value => project.name, :id=> project.id} }.to_json

  end

protected

  def tasks_for_list
    session[:jqgrid_sort_column]= params[:sidx] unless params[:sidx].nil?
    session[:jqgrid_sort_order] = params[:sord] unless params[:sord].nil?
    current_task_filter.tasks_for_jqgrid(params)
  end

end
