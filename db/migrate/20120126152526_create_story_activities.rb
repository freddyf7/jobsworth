class CreateStoryActivities < ActiveRecord::Migration
  def self.up
    create_table :story_activities do |t|
      t.string :name
      t.text :description
      t.integer :task_id
      t.string :status
      
      t.timestamps
    end
  end

  def self.down
    drop_table :story_activities
  end
end
