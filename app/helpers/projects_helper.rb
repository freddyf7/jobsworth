# encoding: UTF-8
module ProjectsHelper
  # get de project leader name
  def get_leader_name (leader_id)
    if !leader_id.nil?
      if leader_id > 0
      user = User.find leader_id
      company_name = Company.find(user.company_id).name.upcase
      @leaderName = user.name + ' (' + company_name + ')'
      end
    else
      @leader_Name = 'No asigned'
    end
  end

  def currency_is_selected? (actual_currency, select_option)
    if (actual_currency == select_option)
    return "selected='" + (actual_currency == select_option).to_s + "'"
    end
  end

  def get_project_total_points(project_id)
    total_points = 0
    stories = Task.where("project_id = ? AND split_status IS NULL",project_id)

    stories.each do |us|
      total_points = total_points + us.total_points
    end

    return total_points
  end
  
  def get_project_burned_points(project_id)
    burned_points = 0
    stories = Task.where("project_id = ? AND split_status IS NULL AND status = 1",project_id)

    stories.each do |us|
      burned_points = burned_points + us.total_points
    end

    return burned_points
  end

  def get_project_remaining_points(project_id)
    remaining_points = 0
    stories = Task.where("project_id = ? AND split_status IS NULL AND status =0",project_id)

    stories.each do |us|
      remaining_points = remaining_points + us.total_points
    end

    return remaining_points
  end

  def get_project_total_business_value(project_id)
    total_value = 0
    stories = Task.where("project_id = ? AND split_status IS NULL",project_id)

    stories.each do |us|
      total_value = total_value + us.business_value
    end

    return total_value
  end

  def get_project_added_business_value(project_id)
    added_value = 0
    stories = Task.where("project_id = ? AND split_status IS NULL AND status = 1",project_id)

    stories.each do |us|
      added_value = added_value + us.business_value
    end

    return added_value
  end

  def get_project_remaining_business_value(project_id)
    remaining_value = 0
    stories = Task.where("project_id = ? AND split_status IS NULL AND status = 0",project_id)

    stories.each do |us|
      remaining_value = remaining_value + us.business_value
    end

    return remaining_value
  end

  def developer_burned_points_project(developer_id,project_id)

    burned_points = 0
    developer = User.find_by_id(developer_id)

    iterations = Milestone.where("project_id = ?", project_id)

    iterations.each do |iteration|
        burned_points = burned_points + iteration.total_points_execute_developer(developer)
    end

    return burned_points
  end

  def developer_avg_burned_points_project(developer_id,project_id)

    burned_points = 0
    developer = User.find_by_id(developer_id)

    iterations = Milestone.where("project_id = ?", project_id)

    iterations.each do |iteration|
        burned_points = burned_points + iteration.total_points_execute_developer(developer)
    end

    avg_burned_points = burned_points/iterations.size

    return avg_burned_points
  end

  def team_velocity_actual_project(project_id)

      total_points = Array.new
      average_velocity_points = 0
      today_date = Date.today


      iterations_before = Milestone.where("project_id = ? AND due_at <= ?",project_id,today_date)

      if iterations_before

        iterations_before.each do |iteration_s|
          if(iteration_s.tasks.size>0)
            total_points << iteration_s.total_points_execute
          end
        end

        if total_points.size > 0
          average_velocity_points = Statistics.mean(total_points)
        end

      end

      return average_velocity_points
  end

  def get_project_current_iteration(project_id)

    hoy = Date.today
    init_hoy = DateTime.new(hoy.year,hoy.month,hoy.day,23,59,59)
    finish_hoy = DateTime.new(hoy.year,hoy.month,hoy.day,0,0,1)
    actual_iteration = Milestone.where("project_id = ? and due_at >= ? and init_date <= ?", project_id,finish_hoy,init_hoy)

    if actual_iteration and actual_iteration.size > 0
      return actual_iteration[0].name
    else
      return "No current iteration"
    end

  end

  def get_project_previous_iteration(project_id)

    hoy = Date.today
    finish_hoy = DateTime.new(hoy.year,hoy.month,hoy.day,0,0,1)
    previous_iteration = Milestone.where("project_id = ? and due_at <= ? and init_date < ?", project_id,finish_hoy,hoy).order("due_at DESC").limit(1)

    if previous_iteration and previous_iteration.size > 0
      return previous_iteration[0]
#    else
#      return "No previous iteration"
    end
  end


end
