module SprintMonitoringHelper

  def options_developers_meeting (selected_project,selected_user)

    if(selected_project.to_i > 0)
    project = Project.find_by_id(selected_project)

    users = project.users

    last_customer = nil
    options = []

    options << [ h(project.customer.name), [] ]
    last_customer = project.customer

    users.each do |user|              
      options.last[1] << [ user.name, user.id ]
    end

    if(selected_user == -1)
      return grouped_options_for_select(options, nil,'Select...').html_safe
    else
      return grouped_options_for_select(options, selected_user.to_i).html_safe
    end
    end
  end

  def options_developers_assign_us (selected_project)

    if(selected_project.to_i > 0)
    project = Project.find_by_id(selected_project)

    users = project.users

    last_customer = nil
    options = []

    options << [ h(project.customer.name), [] ]
    last_customer = project.customer

    users.each do |user|
      options.last[1] << [ user.name, user.id ]
    end

    return grouped_options_for_select(options, nil,'Select...').html_safe

    end
    
  end

  def get_todo_activities(task_id)
     todo_tasks = Array.new
     todo_tasks = StoryActivity.where("task_id = ? and status= 'to_do'",task_id)

     return todo_tasks 
  end

  def get_progress_activities(task_id)
     progress_tasks = Array.new
     progress_tasks = StoryActivity.where("task_id = ? and status= 'progress'",task_id)

     return progress_tasks
  end

  def get_verify_activities(task_id)
     verify_tasks = Array.new
     verify_tasks = StoryActivity.where("task_id = ? and status= 'verify'",task_id)

     return verify_tasks
  end

  def get_done_activities(task_id)
     done_tasks = Array.new
     done_tasks = StoryActivity.where("task_id = ? and status= 'done'",task_id)

     return done_tasks
  end

end
