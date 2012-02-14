class AddUserToStoryActivity < ActiveRecord::Migration
  def self.up
    add_column 'story_activities', 'user_id', :integer
  end

  def self.down
    remove_column 'story_activities', 'user_id'
  end
end
