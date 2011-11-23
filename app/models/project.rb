# encoding: UTF-8
# A logical grouping of milestones and tasks, belonging to a Customer / Client

class Project < ActiveRecord::Base
  # Creates a score_rules association and updates the score
  # of all the task when adding a new score rule
  include Scorable

  belongs_to    :company
  belongs_to    :customer

  has_many      :users, :through => :project_permissions
  has_many      :project_permissions, :dependent => :destroy
  has_many      :pages, :as => :notable, :class_name => "Page", :order => "id desc", :dependent => :destroy
  has_many      :tasks
  has_many      :sheets, :dependent => :destroy
  has_many      :work_logs, :dependent => :destroy
  has_many      :project_files, :dependent => :destroy
  has_many      :project_folders, :dependent => :destroy
  has_many      :milestones, :dependent => :destroy, :order => "due_at asc, lower(name) asc"
  has_many      :roadmap_milestones, :dependent => :nullify


  scope :completed, where("projects.completed_at is not NULL")
  scope :in_progress, where("projects.completed_at is NULL")

  validates_length_of    :name,  :maximum=>200
  validates_presence_of  :name
  validates_presence_of  :customer

  validates :default_estimate,
            :presence      => true,
            :numericality  => { :greater_than_or_equal_to => 1.0 }

  before_destroy :reject_destroy_if_have_tasks

  def full_name
    "#{customer.name} / #{name}"
  end

  def to_s
    name
  end

  def to_css_name
    "#{self.name.underscore.dasherize.gsub(/[ \."',]/,'-')} #{self.customer.name.underscore.dasherize.gsub(/[ \.'",]/,'-')}"
  end

  def total_estimate
    tasks.sum(:duration).to_i
  end

  def work_done
    tasks.sum(:worked_minutes).to_i
  end

  def overtime
    tasks.where("worked_minutes > duration").sum('worked_minutes - duration').to_i
  end

  def total_tasks_count
    if self.total_tasks.nil?
       self.total_tasks = tasks.count
       self.save
    end
    total_tasks
  end

  def open_tasks_count
    if self.open_tasks.nil?
       self.open_tasks = tasks.where("completed_at IS NULL").count
       self.save
    end
    open_tasks
  end

  def total_milestones_count
    if self.total_milestones.nil?
       self.total_milestones = milestones.count
      self.save
    end
    total_milestones
  end

  def open_milestones_count
    if self.open_milestones.nil?
       self.open_milestones = milestones.where("completed_at IS NULL").count
       self.save
    end
    open_milestones
  end

  ###
  # Updates the critical, normal and low counts for this project.
  # Also updates open and total tasks.
  ###
  def update_project_stats
    self.critical_count = tasks.where("task_property_values.property_value_id" => company.critical_values).includes(:task_property_values).count
    self.normal_count = tasks.where("task_property_values.property_value_id" => company.normal_values).includes(:task_property_values).count
    self.low_count = tasks.where("task_property_values.property_value_id" => company.low_values).includes(:task_property_values).count

    self.open_tasks = nil
    self.total_tasks = nil
  end


  #return the estimate global cost of the project
  def get_estimate_cost
    total_estimate_cost_project = 0.0
    iterations = self.milestones
    iterations.each do |iteration|
      total_estimate_cost_project += iteration.get_estimate_cost
    end
    if total_estimate_cost_project.nan?
      total_estimate_cost_project = 0.0
    end
    return (total_estimate_cost_project * 10**2).round.to_f / 10**2 #round two decimals
  end

  #the real cost of the project
  def get_real_cost
    total_real_cost_project = 0.0
    iterations = self.milestones
    iterations.each do |iteration|
      total_real_cost_project += iteration.get_real_cost
    end
    if total_real_cost_project.nan?
      total_real_cost_project = 0.0
    end
    return (total_real_cost_project * 10**2).round.to_f / 10**2 #round two decimals
  end

  #the benefist of the project
  def get_benefist
    return get_estimate_cost - get_real_cost
  end

  #the earned value of the project
  def get_earned_value
    total_ev = 0.0
    iterations = self.milestones
    iterations.each do |iteration|
      total_ev += iteration.get_earned_value
    end
    if total_ev.nan? || total_ev.infinite?
      total_ev = 0.0
    end
    return (total_ev * 10**2).round.to_f / 10**2 #round two decimals
  end

  #return the cost/benefist ratio
  def get_cost_benefis_ratio
    benefist = get_estimate_cost - get_real_cost
    cb = benefist / get_real_cost rescue 0
    if cb.nan? || cb.infinite?
      cb = 0.0
    end
    return (cb * 10**1).round.to_f / 10**1 #round one decimals
  end

   # get the balance of estimate cost and real cost in percent in project
  def get_balance
    estimate_cost = get_estimate_cost
    real_cost = get_real_cost
    balance = ((estimate_cost - real_cost)/estimate_cost) * 100 rescue 0
    if balance.nan? || balance.infinite?
      balance = 0.0
    end
    return balance
  end

  #get the balance in presentation for user interface
  def get_balance_presentation
    balance_amount = get_balance
    word = 'Profit '
    if balance_amount < 0
      word = 'Deficit '
      balance_amount = balance_amount * -1
    else if balance_amount == 0
        word = ""
      end
    end
    return word + balance_amount.to_i.to_s
  end

   #return the roi of the project
  def get_roi
    estimate_cost = get_estimate_cost
    real_cost = get_real_cost
    benefist = estimate_cost
    roi = ((benefist - real_cost)/ real_cost) * 100 rescue 0
    if roi.nan? || roi.infinite?
      roi = 0.0
    end
    return (roi * 10**2).round.to_f / 10**2 #round two decimals
  end

  #return de net present value in one year projection of the global project
  def get_npv
    benefist = get_estimate_cost - get_real_cost
    npv = benefist / (1 + (self.inflation_rate/100))
    if npv.nan? || npv.infinite?
      npv = 0.0
    end
    return (npv * 10**2).round.to_f / 10**2 #round two decimals
  end

  #boolean return if currency for project if change
  def currency_change? (new_currency_iso_code)
    return (new_currency_iso_code != self.currency_iso_code)
  end



  private

  def reject_destroy_if_have_tasks
    unless tasks.count.zero?
      errors.add(:base, "Can not delete project, please remove tasks from this project.")
      return false
    end
    true
  end
end





# == Schema Information
#
# Table name: projects
#
#  id               :integer(4)      not null, primary key
#  name             :string(200)     default(""), not null
#  company_id       :integer(4)      default(0), not null
#  customer_id      :integer(4)      default(0), not null
#  created_at       :datetime
#  updated_at       :datetime
#  completed_at     :datetime
#  critical_count   :integer(4)      default(0)
#  normal_count     :integer(4)      default(0)
#  low_count        :integer(4)      default(0)
#  description      :text
#  open_tasks       :integer(4)
#  total_tasks      :integer(4)
#  total_milestones :integer(4)
#  open_milestones  :integer(4)
#  leader_id :integer(4)
#  currency_iso_code:string
#
# Indexes
#
#  projects_company_id_index   (company_id)
#  projects_customer_id_index  (customer_id)
#  fk_projects_leader_id (user_id)
#

