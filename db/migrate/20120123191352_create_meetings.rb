class CreateMeetings < ActiveRecord::Migration
  def self.up
    create_table :meetings do |t|
      t.datetime :day
      t.text :done
      t.text :to_do
      t.text :observation
      t.integer :user_id
      t.integer :milestone_id

      t.timestamps
    end
  end

  def self.down
    drop_table :meetings
  end
end
