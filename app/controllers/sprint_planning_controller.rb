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

    if params[:milestone_id].nil?
      session[:id_milestone] =-1
    else
      session[:id_milestone] = params[:milestone_id]
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

      @total_points = 0
      @total_business_value = 0

      @sprint_tasks.each do |us|
      @total_points = @total_points + us.total_points
      @total_business_value = @total_business_value + us.business_value
      end

    end

    respond_to do |format|
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

    @total_points = 0
    @total_business_value = 0

    @tasks.each do |us|
      @total_points = @total_points + us.total_points
      @total_business_value = @total_business_value + us.business_value
    end

    respond_to do |format|
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

    redirect_to '/sprint_planning/planning'
  end


  def auto_complete_for_milestone_project_name

    text = params[:term]

    if !text.blank?
      @projects = current_user.company.projects.where("lower(name) like ?", "%#{ text }%")
    end

    render :json=> @projects.collect{|project| {:value => project.name, :id=> project.id} }.to_json

  end


  def developer_velocity

    if params[:project_id].to_i > 0

      proyecto_actual = Project.find_by_id(params[:project_id])
      developer = User.find_by_id(params[:developer_id])
      hoy = Date.today

      dev_velocity_actual_project(proyecto_actual,hoy,developer)

      dev_velocity_previous_project(proyecto_actual,hoy,developer)

      dev_velocity_second_previous_project(proyecto_actual,hoy,developer)

    end
    render :partial => 'sprint_planning/velocity'
  end
  

  def team_velocity    

    if params[:project_id].to_i > 0

      proyecto_actual = Project.find_by_id(params[:project_id])
      developer = User.find_by_id(params[:developer_id])
      hoy = Date.today

      team_velocity_actual_project(proyecto_actual,hoy,developer)

      team_velocity_previous_project(proyecto_actual,hoy,developer)

      team_velocity_second_previous_project(proyecto_actual,hoy,developer)

    end
    render :partial => 'sprint_planning/velocity'
  end

protected

  def dev_velocity_actual_project(proyecto_actual,hoy,developer)

      total_points = Array.new
      average_velocity_points = 0

      iteracion_actual = Milestone.find(:all, :conditions => ["due_at > ? and project_id = ?",hoy,proyecto_actual.id])
      iteration = Milestone.find_by_id(iteracion_actual[0].id)
      iterations_before = Milestone.find(:all, :conditions => ["due_at < ? and project_id=?",iteration.init_date,proyecto_actual.id])
      @project_json = proyecto_actual

      iterations_before.each do |iteration_s|
        if(iteration_s.tasks.size>0)
          total_points << iteration_s.total_points_execute_developer(developer)
        end
      end

      if total_points.size > 0
       average_velocity_points = Statistics.mean(total_points)
       @puntos = average_velocity_points
      end
  end

  def dev_velocity_previous_project(proyecto_actual,hoy,developer)

      total_points = Array.new
      average_velocity_points = 0
      proyecto = Project.new
      iterations = Array.new

      proyecto = Project.where("completed_at < ?",proyecto_actual.created_at).order("completed_at DESC").limit(1)
      @previous_project = proyecto[0].name
      iterations = Milestone.where("project_id=?",proyecto[0].id)
      total_points.clear

      iterations.each do |iteration_s|
        if(iteration_s.tasks.size>0)
          total_points << iteration_s.total_points_execute_developer(developer)
        end
      end

      if total_points.size > 0
       @previous_points = Statistics.mean(total_points)
      end

  end

  def dev_velocity_second_previous_project(proyecto_actual,hoy,developer)
      
      total_points = Array.new
      average_velocity_points = 0
      average_velocity_points = 0
      proyecto = Project.where("completed_at < ?",proyecto_actual.created_at).order("completed_at DESC").limit(2)
      @previous_project_2 = proyecto[1].name
      iterations = Milestone.where("project_id=?",proyecto[1].id)
      total_points.clear

      iterations.each do |iteration_s|
        if(iteration_s.tasks.size>0)
          total_points << iteration_s.total_points_execute_developer(developer)
        end
      end

      if total_points.size > 0
        @previous_points_2 = Statistics.mean(total_points)
      end
  end

  def team_velocity_actual_project(proyecto_actual,hoy,developer)

      total_points = Array.new
      average_velocity_points = 0

      iteracion_actual = Milestone.find(:all, :conditions => ["due_at > ? and project_id = ?",hoy,proyecto_actual.id])
      iteration = Milestone.find_by_id(iteracion_actual[0].id)
      iterations_before = Milestone.find(:all, :conditions => ["due_at < ? and project_id=?",iteration.init_date,proyecto_actual.id])
      @project_json = proyecto_actual

      iterations_before.each do |iteration_s|
        if(iteration_s.tasks.size>0)
          total_points << iteration_s.total_points_execute
        end
      end

      if total_points.size > 0
       average_velocity_points = Statistics.mean(total_points)
       @puntos = average_velocity_points
      end
  end

  def team_velocity_previous_project(proyecto_actual,hoy,developer)

      total_points = Array.new
      proyecto = Project.new
      iterations = Array.new

      proyecto = Project.where("completed_at < ?",proyecto_actual.created_at).order("completed_at DESC").limit(1)
      @previous_project = proyecto[0].name
      iterations = Milestone.where("project_id=?",proyecto[0].id)
      total_points.clear

      iterations.each do |iteration_s|
        if(iteration_s.tasks.size>0)
          total_points << iteration_s.total_points_execute
        end
      end

      if total_points.size > 0
       @previous_points = Statistics.mean(total_points)
      end
  end

  def team_velocity_second_previous_project(proyecto_actual,hoy,developer)

      total_points = Array.new

      proyecto = Project.where("completed_at < ?",proyecto_actual.created_at).order("completed_at DESC").limit(2)
      @previous_project_2 = proyecto[1].name
      iterations = Milestone.where("project_id=?",proyecto[1].id)
      total_points.clear

      iterations.each do |iteration_s|
        if(iteration_s.tasks.size>0)
          total_points << iteration_s.total_points_execute
        end
      end

      if total_points.size > 0
        @previous_points_2 = Statistics.mean(total_points)
      end
  end

 
  def tasks_for_list
    session[:jqgrid_sort_column]= params[:sidx] unless params[:sidx].nil?
    session[:jqgrid_sort_order] = params[:sord] unless params[:sord].nil?
    current_task_filter.tasks_for_jqgrid(params)
  end


end
