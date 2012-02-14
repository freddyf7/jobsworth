module SprintClosingHelper

  def developer_avg_velocity(developer_id,iteration_id)

    iteration = Milestone.find_by_id(iteration_id)
    developer = User.find_by_id(developer_id)

    burned_points = iteration.total_points_execute_developer(developer)

    return burned_points
  end

end
