class CreateRestrospectives < ActiveRecord::Migration
  def self.up
    create_table :restrospectives do |t|
      t.integer :milestone_id
      t.text :observation

      t.timestamps
    end
  end

  def self.down
    drop_table :restrospectives
  end
end
