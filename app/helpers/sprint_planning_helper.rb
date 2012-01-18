module SprintPlanningHelper

  def options_milestone_sprint_planning(project_id,selected_milestone)
    milestones = Milestone.not_completed.
                  order('due_at, name').
                  where('company_id = ? AND project_id = ?',
                    current_user.company.id, project_id)
    if milestones.size > 0
      last_project = nil
      options = []

      milestones.each do |milestone|
        if milestone.project.name != last_project
          options << [ h(milestone.project.name), [] ]
          last_project = milestone.project.name
        end

        options.last[1] << [ milestone.name, milestone.id ]
      end

      if(selected_milestone == -1)
      return grouped_options_for_select(options, nil,'Select...').html_safe
      else
      return grouped_options_for_select(options, selected_milestone.to_i).html_safe
    end
    else
      return 'No Iterations'
    end
  end

end
