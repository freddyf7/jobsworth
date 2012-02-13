class AddSplitStatusToTask < ActiveRecord::Migration
  def self.up
    add_column 'tasks', 'split_status', :integer
  end

  def self.down
    remove_column 'tasks', 'split_status'
  end
end
