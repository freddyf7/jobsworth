class SprintPlanningController < ApplicationController

  def planning
    @project = Project.new(params[:project])


    respond_to do |format|
      format.html  # planning.html.erb
#     format.json  { render :json => @posts }
    end
  end

  def auto_complete_for_milestone_project_name
    text = params[:term]
    if !text.blank?
      @projects = current_user.company.projects.where("lower(name) like ?", "%#{ text }%")
    end
    render :json=> @projects.collect{|project| {:value => project.name, :id=> project.id} }.to_json

  end

end
