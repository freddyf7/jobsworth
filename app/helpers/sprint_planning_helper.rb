module SprintPlanningHelper

  def options_milestone_sprint_planning(project_id)
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

      return grouped_options_for_select(options, milestones[0].id).html_safe
    else
      return 'No Iterations'
    end
  end

end
