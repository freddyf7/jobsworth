class SprintPlanningController < ApplicationController

  def planning

    #para que el combobox de proyecto cargue con un proyecto
#    if (params[:project_id].nil? or params[:project_id] == 0)
#      backlog_project = current_task_filter.tasks[0].project.id
#      session[:id_prj] = backlog_project
#    else
#      session[:id_prj] = params[:project_id]
#    end

    if params[:project_id].nil?

#      if current_task_filter.tasks.size > 0
#        backlog_project = current_task_filter.tasks[0].project.id
#        session[:id_prj] = backlog_project
#        @project = Project.find_by_id(backlog_project)
#      else
#        roadmap_project = current_user.projects.first
#        project_id = roadmap_project.id
        session[:id_prj] =-1
#      end
    else
      session[:id_prj] = params[:project_id]
      @project = Project.find_by_id(params[:project_id])

    end

    @sprint_tasks = Array.new

    arreglo = params[:user_stories]
    i=0
    if !params[:user_stories].nil?
      arreglo_2 = arreglo.split("-")

      for i in 0..arreglo_2.size-1 do
        if (arreglo_2[i] != '-' && arreglo_2[i] != '')
          tarea = Task.find_by_id(arreglo_2[i].to_i)
          @sprint_tasks << tarea
        end
      end
    end

    owner = Task.find_by_id(2)
    respond_to do |format|
#      flash['notice'] = _("owner:"+owner.owners[0].to_s)
      format.html { render :action => "planning_backlog_grid" }
      format.json { render :template => "sprint_planning/backlog_list.json"}
    end

  end

  def product_backlog

    sprint_tasks = Array.new
    arreglo = params[:user_stories_2]
    i=0
    if !params[:user_stories_2].nil? && params[:user_stories_2]!='-'
      arreglo_2 = arreglo.split("-")

      for i in 0..arreglo_2.size-1 do
        if (arreglo_2[i] != '-' && arreglo_2[i] != '')
          tarea = Task.find_by_id(arreglo_2[i].to_i)
          sprint_tasks << tarea
        end
      end
      @tasks = tasks_for_list - sprint_tasks
    else
      @tasks = tasks_for_list
    end

    respond_to do |format|
#      format.html { render :action => "planning_backlog_grid" }
      format.json { render :template => "tasks/backlog_list.json"}
    end

  end

  def saveSprint

    historias_params = params[:historias]
    sprintSave = Array.new
    iteracion = params[:iteracion]

    historias = historias_params.split("-")
    
    for i in 0..historias.size-1 do
        if (historias[i] != '-' && historias[i] != '')
          tarea = Task.find_by_id(historias[i].to_i)
          sprintSave << tarea
        end
    end

    sprintSave.each do |us|
      us.milestone_id = iteracion
      us.save!
    end

#    task = Task.find_by_id(5)
#    task.milestone_id = 8
#    task.save!
    redirect_to '/sprint_planning/planning'
  end


  def auto_complete_for_milestone_project_name
    text = params[:term]
    if !text.blank?
      @projects = current_user.company.projects.where("lower(name) like ?", "%#{ text }%")
    end
    render :json=> @projects.collect{|project| {:value => project.name, :id=> project.id} }.to_json

  end

  def add_velocity_actual_project
    proyecto_actual = params[:project_id]
    hoy = Date.today
    developer = User.find_by_id(params[:developer_id])
    iteracion_actual = Milestone.find(:all, :conditions => ["due_at > ? and project_id = ?",hoy,proyecto_actual])
    if params[:project_id].to_i > 0
      average_velocity_points = 0
      iteration = Milestone.find_by_id(iteracion_actual[0].id)
      project = Project.find_by_id(proyecto_actual)
      iterations_before = Milestone.find(:all, :conditions => ["due_at < ? and project_id=?",iteration.init_date,proyecto_actual])
      total_points = Array.new
      total_stories = Array.new
      iterations_before.each do |iteration_s|

      if(iteration_s.tasks.size>0)
        total_points << iteration_s.total_points_execute_developer(developer)
#       total_stories << iteration_s.total_task_execute_developer
      end
      end
#    if total_points.size > 0 && total_stories.size > 0
      if total_points.size > 0
       average_velocity_points = Statistics.mean(total_points)
#      average_total_stories = Statistics.mean(total_stories)
#      result = (average_velocity_points.to_f / average_total_stories.to_f).ceil
#      res = result.to_s
        res = average_velocity_points
      else
        res = "2"
      end
    else
    res = "3"
    end
    render :text => res
  end


  def add_velocity_previous_project
    proyecto_actual = Project.find_by_id(params[:project_id])
    developer = User.find_by_id(params[:developer_id])
    hoy = Date.today
    proyecto = Project.new
    iterations = Array.new
#    iteracion_actual = Milestone.find(:all, :conditions => ["due_at > ? and project_id = ?",hoy,proyecto_actual])
    if params[:project_id].to_i > 0
      average_velocity_points = 0
      proyecto = Project.where("completed_at < ?",proyecto_actual.created_at).order("completed_at DESC").limit(1)
#      proyecto = Project.where("completed_at < ?",proyecto_actual.created_at)
#      proyecto = Project.find_by_id(871498796)
      iterations = Milestone.where("project_id=?",proyecto[0].id)
      
      total_points = Array.new
      total_stories = Array.new
      iterations.each do |iteration_s|

        if(iteration_s.tasks.size>0)
          total_points << iteration_s.total_points_execute_developer(developer)
#         total_stories << iteration_s.total_task_execute_developer
        end
      end
#    if total_points.size > 0 && total_stories.size > 0
      if total_points.size > 0
        average_velocity_points = Statistics.mean(total_points)
#      average_total_stories = Statistics.mean(total_stories)
#      result = (average_velocity_points.to_f / average_total_stories.to_f).ceil
#      res = result.to_s
       res = average_velocity_points

      else
        res = "2"
      end
    else
    res = "3"
    end
    render :text => res

  end


  def add_velocity_previous_project_2
    proyecto_actual = Project.find_by_id(params[:project_id])
    developer = User.find_by_id(params[:developer_id])
    hoy = Date.today
    proyecto = Project.new
    iterations = Array.new
#    iteracion_actual = Milestone.find(:all, :conditions => ["due_at > ? and project_id = ?",hoy,proyecto_actual])
    if params[:project_id].to_i > 0
      average_velocity_points = 0
      proyecto = Project.where("completed_at < ?",proyecto_actual.created_at).order("completed_at DESC").limit(2)
#      proyecto = Project.where("completed_at < ?",proyecto_actual.created_at)
#      proyecto = Project.find_by_id(871498796)
      iterations = Milestone.where("project_id=?",proyecto[1].id)

      total_points = Array.new
      total_stories = Array.new
      iterations.each do |iteration_s|

      if(iteration_s.tasks.size>0)
        total_points << iteration_s.total_points_execute_developer(developer)
#       total_stories << iteration_s.total_task_execute_developer
      end
      
      end
#    if total_points.size > 0 && total_stories.size > 0
      if total_points.size > 0
        average_velocity_points = Statistics.mean(total_points)
#      average_total_stories = Statistics.mean(total_stories)
#      result = (average_velocity_points.to_f / average_total_stories.to_f).ceil
#      res = result.to_s
       res = average_velocity_points
      else
        res = "2"
      end
    else
    res = "3"
    end
    render :text => res
  end

  def projectName
    
    project = Project.find_by_id(params[:project_id])
    res = project.name

    render :text => res
  end




protected

  def tasks_for_list
    session[:jqgrid_sort_column]= params[:sidx] unless params[:sidx].nil?
    session[:jqgrid_sort_order] = params[:sord] unless params[:sord].nil?
    current_task_filter.tasks_for_jqgrid(params)
  end


end
