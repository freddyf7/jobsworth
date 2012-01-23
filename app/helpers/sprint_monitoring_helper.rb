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
end
