# encoding: UTF-8
# Handle Projects for a company, including permissions
class ProjectsController < ApplicationController
  before_filter :protect_admin_area, :except=>[:new, :create, :list_completed, :list ]
  before_filter :scope_projects, :except=>[:new, :create]
  def new
    unless current_user.create_projects?
      flash['notice'] = _"You're not allowed to create new projects. Have your admin give you access."
      redirect_from_last
      return
    end

    @project = Project.new
  end

  def create
    unless current_user.create_projects?
      flash['notice'] = _"You're not allowed to create new projects. Have your admin give you access."
      redirect_from_last
      return
    end

    @project = Project.new(params[:project])
    @project.company_id = current_user.company_id

    if @project.save
      if params[:copy_project].to_i > 0
        project = current_user.all_projects.find(params[:copy_project])
        project.project_permissions.each do |perm|
          p = perm.clone
          p.project_id = @project.id
          p.save

          if p.user_id == current_user.id
            @project_permission = p
          end

        end
      end

      @project_permission ||= ProjectPermission.new

      @project_permission.user_id = current_user.id
      @project_permission.project_id = @project.id
      @project_permission.company_id = current_user.company_id
      @project_permission.set('all')
      @project_permission.save

      #add permision for leader
      if !@project.leader_id.nil?
        if current_user.id != @project.leader_id
          @project_permission_l ||= ProjectPermission.new
          @project_permission_l.user_id = @project.leader_id
          @project_permission_l.project_id = @project.id
          @project_permission_l.company_id = current_user.company_id
          @project_permission_l.set('all')
          @project_permission_l.save
        end
      end


      if @project.company.users.size == 1
        flash['notice'] = _('Project was successfully created.')
        redirect_to :action => 'list'
      else
        flash['notice'] = _('Project was successfully created. Add users who need access to this project.')
        redirect_to :action => 'edit', :id => @project
      end
    else
      render :action => 'new'
    end
  end

  def edit
    @project = @project_relation.find(params[:id])
    if @project.nil?
      redirect_to :controller => 'activities', :action => 'list'
      return false
    end
    @users = User.where("company_id = ?", current_user.company_id).order("users.name")
  end

  def ajax_remove_permission
    permission = ProjectPermission.where("user_id = ? AND project_id = ? AND company_id = ?", params[:user_id], params[:id], current_user.company_id).first

    if params[:perm].nil?
      permission.destroy
    else
      permission.remove(params[:perm])
      permission.save
    end

    if params[:user_edit]
      @user = current_user.company.users.find(params[:user_id])
      render :partial => "/users/project_permissions"
    else
      @project = current_user.projects.find(params[:id])
      @users = Company.find(current_user.company_id).users.order("users.name")
      render :partial => "permission_list"
    end
  end

  def ajax_add_permission
    user = User.active.where("company_id = ?", current_user.company_id).find(params[:user_id])

    begin
      if current_user.admin?
        @project = current_user.company.projects.find(params[:id])
      else
        @project = current_user.projects.find(params[:id])
      end
    rescue
      render :update do |page|
        page.visual_effect(:highlight, "user-#{params[:user_id]}", :duration => 1.0, :startcolor => "'#ff9999'")
      end
      return
    end

    if @project && user && ProjectPermission.where("user_id = ? AND project_id = ?", user.id, @project.id).empty?
      permission = ProjectPermission.new
      permission.user_id = user.id
      permission.project_id = @project.id
      permission.company_id = current_user.company_id
      permission.can_comment = 1
      permission.can_work = 1
      permission.can_close = 1
      permission.save
    else
      permission = ProjectPermission.where("user_id = ? AND project_id = ? AND company_id = ?", params[:user_id], params[:id], current_user.company_id).first
      permission.set(params[:perm])
      permission.save
    end

    if params[:user_edit] && current_user.admin?
      @user = current_user.company.users.find(params[:user_id])
      render :partial => "users/project_permissions"
    else
      @users = Company.find(current_user.company_id).users.order("users.name")
      render :partial => "permission_list"
    end
  end

  def update
    @project = @project_relation.in_progress.find(params[:id])
    old_client = @project.customer_id
    old_name = @project.name
    old_project = @project

    if @project.update_attributes(params[:project])

      #Need to update leader? => add permision for project if no exist
      if (leader_change(params[:project][:leader_id], old_project))
        if (!leader_already_member(params[:project][:leader_id], old_project))
          @project_permission = ProjectPermission.new
          @project_permission.user_id = params[:project][:leader_id]
          @project_permission.project_id = @project.id
          @project_permission.company_id = current_user.company_id
          @project_permission.set('all')
          @project_permission.save
        end
      end
      
      # Need to update work-sheet entries?
      if @project.customer_id != old_client
        WorkLog.update_all("customer_id = #{@project.customer_id}", "project_id = #{@project.id} AND customer_id != #{@project.customer_id}")
      end

      flash['notice'] = _('Project was successfully updated.')
      redirect_to :action=> "list"
    else
      render :action => 'edit'
    end
  end

  def destroy
    project=@project_relation.find(params[:id])
    if project.destroy
      flash['notice'] = _('Project was deleted.')
    else
      flash['notice'] = project.errors[:base].join(', ')
    end

    redirect_to :controller => 'projects', :action => 'list'
  end

  def complete
    project = @project_relation.in_progress.find(params[:id])
    unless project.nil?
      project.completed_at = Time.now.utc
      project.save
      flash[:notice] = _("%s completed.", project.name )
    end
    redirect_to :controller => 'activities', :action => 'list'
  end

  def revert
    project = @project_relation.completed.find(params[:id])
    unless project.nil?
      project.completed_at = nil
      project.save
      flash[:notice] = _("%s reverted.", project.name)
    end
    redirect_to :controller => 'activities', :action => 'list'
  end

  def list_completed
    @completed_projects = @project_relation.completed.order("completed_at DESC")
  end

  def list
    @projects = @project_relation.in_progress.order('customer_id').includes(:customer, :milestones).paginate(:page => params[:page], :per_page => 100)
    @completed_projects = @project_relation.completed
  end
  private

  def scope_projects
    if current_user.admin?
      @project_relation = current_user.company.projects
    else
      @project_relation = current_user.all_projects
    end
  end

  def protect_admin_area
    return true if current_user.admin?
    flash['notice'] = _"You haven't access to this area."
    redirect_from_last
    return false
  end

  def leader_change (form_leader_id, project)
    old_project = Project.find project.id
    actual_leader = old_project.leader_id
    return form_leader_id != actual_leader
  end

  def leader_already_member(form_leader_id,project)
    project_permissions = ProjectPermission.find(:first, :conditions => ['user_id = ? AND project_id = ?',form_leader_id,project.id])
    return !project_permissions.nil?
  end

end
