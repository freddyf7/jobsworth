# encoding: UTF-8
# Handle Projects for a company, including permissions
require 'money'
require 'money/bank/google_currency'
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
      estimation_settings = EstimationSetting.new
      estimation_settings.project_id = @project.id
      estimation_settings.save!
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
    Money.default_bank = Money::Bank::GoogleCurrency.new
    Money.add_rate("USD", "VEF", 4.6000)
    Money.add_rate("VEF", "USD", 1/4.6000)
    Money.add_rate("EUR", "VEF", 5.0)
    Money.add_rate("VEF", "EUR", 1/5.0)
    @project = @project_relation.in_progress.find(params[:id])
    old_client = @project.customer_id
    old_name = @project.name
    old_project = @project

    if (@project.currency_change?(params[:project][:currency_iso_code]))
      new_cost_per_hour = @project.cost_per_hour.to_money(@project.currency_iso_code.to_sym).exchange_to(params[:project][:currency_iso_code].to_sym)
      params[:project][:cost_per_hour] = new_cost_per_hour
    end

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

  def config_full_report
    @project_id = params[:id_prj].to_i
    render :layout => false
  end


  def full_report
    @project = Project.find params[:id_prj].to_i
    iterations = @project.milestones

    #form configuration
    @general_aspects = params[:general_aspects]
    @financial_aspects = params[:financial_aspects]
    @points_aspects = params[:points_aspects]
    @earned_value = params[:earned_value]
    @ev_vs_vp = params[:ev_vs_vp]
    @velocity = params[:velocity]
    @type = params[:type]
    @business = params[:business]
    @roi = params[:roi]

    #Earned Value report
    values_col_ev = Array.new
    @currency_ev = @project.currency_iso_code
    @values_ev = "";
    @iterations_ev = "";
    count = 1
    iterations.each do |i|
      values_col_ev << i.get_earned_value
      @values_ev += i.get_earned_value > 0 ? (i.get_earned_value).to_s : 0.to_s
      if count < iterations.size
        @values_ev += ","
      end
      @iterations_ev += "|Iter" + count.to_s+ "|"
      count = count + 1
    end
    @max_ev = Statistics.greather_num(values_col_ev) > 0 ? Statistics.greather_num(values_col_ev).to_s : 1000.to_s
    acum = @max_ev.to_i / 6
    @mid_ev = (@max_ev.to_i / 2).ceil.to_s
    @mid_1_ev = acum.to_s
    @mid_2_ev = (@mid_1_ev.to_i + acum).to_s
    @mid_4_ev = (@mid_ev.to_i + acum).to_s
    @mid_5_ev = (@mid_4_ev.to_i + acum).to_s
    #end earned value report

    #ev vs pv report
    values_col_evpv = Array.new
    @currency_evpv = @project.currency_iso_code
    values_ev = ""
    values_rc = ""
    values_pc = ""
    @iterations_evpv = ""
    count = 1
    iterations.each do |i|
      if i.get_estimate_cost > 0
        values_col_evpv << i.get_earned_value
        values_col_evpv << i.get_real_cost
        values_col_evpv << i.get_estimate_cost
        values_ev += i.get_earned_value > 0 ? (i.get_earned_value).to_s : 0.to_s
        values_rc += i.get_real_cost > 0 ? (i.get_real_cost).to_s : 0.to_s
        values_pc += i.get_estimate_cost > 0 ? (i.get_estimate_cost).to_s : 0.to_s
        if count <= iterations.size
          values_ev += ","
          values_rc += ","
          values_pc += ","
        end
        @iterations_evpv += "|Iter" + count.to_s+ "|"
        count = count + 1
      end
    end
    @values_evpv = values_rc.chop + '|' + values_ev.chop + '|' + values_pc.chop
    @max_evpv = Statistics.greather_num(values_col_evpv) > 0 ? Statistics.greather_num(values_col_evpv).to_s : 1000.to_s
    acum = @max_evpv.to_i / 6
    @mid_evpv = (@max_evpv.to_i / 2).ceil.to_s
    @mid_1_evpv = acum.to_s
    @mid_2_evpv = (@mid_1_evpv.to_i + acum).to_s
    @mid_4_evpv = (@mid_evpv.to_i + acum).to_s
    @mid_5_evpv = (@mid_4_evpv.to_i + acum).to_s
    #end ev vs pv report

    #team velocity report
    values_col_v = Array.new
    values_velocity = ""
    values_target = ""
    @iterations_v = ""
    count = 1
    iterations.each do |i|
      if i.get_estimate_cost > 0
        values_col_v << i.get_team_velocity
        values_col_v << i.total_points
        values_velocity += i.get_team_velocity > 0 ? (i.get_team_velocity).to_s : 0.to_s
        values_target += i.total_points > 0 ? (i.total_points).to_s : 0.to_s
        if count <= iterations.size
          values_velocity += ","
          values_target += ","
        end
        @iterations_v += "Iter" + count.to_s+ "|"
        count = count + 1
      end
    end
    @values_v = values_velocity.chop + '|' + values_target.chop
    @max_v = Statistics.greather_num(values_col_v) > 0 ? Statistics.greather_num(values_col_v).to_s : 1000.to_s
    acum = @max_v.to_i / 6
    @mid_v = (@max_v.to_i / 2).ceil.to_s
    @mid_1_v = acum.to_s
    @mid_2_v = (@mid_1_v.to_i + acum).to_s
    @mid_4_v = (@mid_v.to_i + acum).to_s
    @mid_5_v = (@mid_4_v.to_i + acum).to_s
    #end team velocity report

     #types history
    project = @project
    values_col_t = Array.new
    @task_type = project.tasks.find_all_by_type("Task").count
    values_col_t << @task_type
    @epic_type = project.tasks.find_all_by_type("Epic").count
    values_col_t << @epic_type
    @improvement_type = project.tasks.find_all_by_type("Improvement").count
    values_col_t << @improvement_type
    @nf_type = project.tasks.find_all_by_type("New Feature").count
    values_col_t << @nf_type
    @defect_type = project.tasks.find_all_by_type("New Feature").count
    values_col_t << @defect_type
    @max_t = Statistics.greather_num(values_col_t) > 0 ? Statistics.greather_num(values_col_t).to_s : 100.to_s
    @mid_t = (@max_t.to_i / 2).ceil.to_s
    #end types_history

    #business value
    project = @project
    iterations_bus = project.milestones
    values_col_bus = Array.new
    values_bvp = ""
    values_ep = ""
    values_er = ""
    @iterations = ""
    count = 1
    iterations.each do |i|
      if i.total_points > 0
        values_col_bus << i.total_points
        values_col_bus << i.total_points_execute
        values_col_bus << i.real_business_value
        values_bvp += i.real_business_value > 0 ? (i.real_business_value).to_s : 0.to_s
        values_ep += i.total_points > 0 ? (i.total_points).to_s : 0.to_s
        values_er += i.total_points_execute > 0 ? (i.total_points_execute).to_s : 0.to_s
        if count <= iterations.size
          values_bvp += ","
          values_ep += ","
          values_er += ","
        end
        @iterations += "|Iter" + count.to_s+ "|"
        count = count + 1
      end
    end
    @values_bus = values_bvp.chop + '|' + values_ep.chop + '|' + values_er.chop
    @max_bus = Statistics.greather_num(values_col_bus) > 0 ? Statistics.greather_num(values_col_bus).to_s : 1000.to_s
    acum = @max_bus.to_i / 6
    @mid_bus = (@max_bus.to_i / 2).ceil.to_s
    @mid_1_bus = acum.to_s
    @mid_2_bus = (@mid_1_bus.to_i + acum).to_s
    @mid_4_bus = (@mid_bus.to_i + acum).to_s
    @mid_5_bus = (@mid_4_bus.to_i + acum).to_s
    #end business_value

    #roi
    project = @project
    iterations = project.milestones
    values_col = Array.new
    @currency = project.currency_iso_code
    @values_roi = "";
    @iterations = "";
    count = 1
    iterations.each do |i|
      values_col << i.get_roi
      @values_roi += i.get_roi > 0 ? (i.get_roi).to_s : 0.to_s
      if count < iterations.size
        @values_roi += ","
      end
      @iterations += "|Iter" + count.to_s+ "|"
      count = count + 1
    end
    @max = Statistics.greather_num(values_col) > 0 ? Statistics.greather_num(values_col).to_s : 1000.to_s
    acum = @max.to_i / 6
    @mid = (@max.to_i / 2).ceil.to_s
    @mid_1 = acum.to_s
    @mid_2 = (@mid_1.to_i + acum).to_s
    @mid_4 = (@mid.to_i + acum).to_s
    @mid_5 = (@mid_4.to_i + acum).to_s
    #end roi

    render :layout => false
  end


  def dashboard
    @projects = Project.all
    

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
