# encoding: UTF-8
# A user from a company
require 'digest/md5'

class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :lockable and :timeoutable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :working_hours
  has_many(:custom_attribute_values, :as => :attributable, :dependent => :destroy,
           # set validate = false because validate method is over-ridden and does that for us
           :validate => false)
  include CustomAttributeMethods

  belongs_to    :company
  belongs_to    :customer
  belongs_to    :access_level
  has_many      :projects, :through => :project_permissions, :source=>:project, :conditions => ['projects.completed_at IS NULL'], :order => "projects.customer_id, projects.name", :readonly => false
  has_many      :completed_projects, :through => :project_permissions, :conditions => ['projects.completed_at IS NOT NULL'], :source => :project, :order => "projects.customer_id, projects.name", :readonly => false
  has_many      :all_projects, :through => :project_permissions, :order => "projects.customer_id, projects.name", :source => :project, :readonly => false
  has_many      :project_permissions, :dependent => :destroy

  has_many      :pages, :dependent => :nullify
  has_many      :notes, :as => :notable, :class_name => "Page", :order => "id desc"

  has_many      :tasks, :through => :task_owners
  has_many      :task_owners, :dependent => :destroy
  has_many      :work_logs

  has_many      :notifications, :class_name=>"TaskWatcher", :dependent => :destroy
  has_many      :notifies, :through => :notifications, :source => :task

  has_many      :widgets, :order => "widgets.column, widgets.position", :dependent => :destroy

  has_many      :task_filters, :dependent => :destroy
  has_many      :visible_task_filters, :source => "task_filter", :through => :task_filter_users, :order => "task_filters.name"
  has_many      :task_filter_users, :dependent => :delete_all

  has_many      :sheets, :dependent => :destroy

  has_many      :preferences, :as => :preferencable
  has_many      :email_addresses, :dependent=>:destroy, :order => "email_addresses.default DESC"

  has_many      :email_deliveries

  has_many      :planning_poker_votes, :dependent=>:destroy

  has_attached_file :avatar, :whiny => false , :styles=>{ :small=> "25x25>", :large=>"50x50>"}, :path => File.join(Rails.root.to_s, 'store', 'avatars')+ "/:id_:basename_:style.:extension"

  include PreferenceMethods

  validates_length_of           :name,  :maximum=>200, :allow_nil => true
  validates_presence_of         :name

  validates :username,
            :presence => true,
            :length => {:minimum => 3, :maximum => 200},
            :uniqueness => { :case_sensitive => false, :scope => "company_id" }

  validates :password, :confirmation => true, :if => :password_required?


  validates_presence_of         :company
  validates :date_format, :presence => true, :inclusion => {:in => %w(%m/%d/%Y %d/%m/%Y %Y-%m-%d)}
  validates :time_format, :presence => true, :inclusion => {:in => %w(%H:%M %I:%M%p)}
  validate :validate_custom_attributes

  validates :working_hours,
            :presence             => true,
            :working_hours_format => true


  before_create     :generate_uuid
  after_create      :generate_widgets
  before_validation :set_date_time_formats, :on => :create
  before_destroy :reject_destroy_if_exist
  ACCESS_CONTROL_ATTRIBUTES=[:create_projects, :use_resources, :read_clients, :create_clients, :edit_clients, :can_approve_work_logs]
  attr_protected :uuid, :autologin, :admin, ACCESS_CONTROL_ATTRIBUTES, :company_id

  scope :auto_add, where(:auto_add_to_customer_tasks => true)
  scope :by_email, lambda{ |email|
    where('email_addresses.email' => email, 'email_addresses.default' => true).joins(:email_addresses).readonly(false)
  }
  scope :active, where(:active => true)
  ###
  # Searches the users for company and returns
  # any that have names or ids that match at least one of
  # the given strings
  ###
  def self.search(company, strings)
    conds = Search.search_conditions_for(strings, [ :name ], :start_search_only => true)
    return company.users.where(conds)
  end
  def set_access_control_attributes(params)
    ACCESS_CONTROL_ATTRIBUTES.each do |attr|
      next if params[attr].nil?
      self.attributes[:attr]=attr
    end
  end
  def avatar_path
    avatar.path(:small)
  end

  def avatar_large_path
    avatar.path(:large)
  end

  def avatar?
    !self.avatar_path.nil? and File.exist?(self.avatar_path)
  end

  def generate_uuid
    self.uuid ||= Digest::MD5.hexdigest( rand(100000000).to_s + Time.now.to_s)
    self.autologin ||= Digest::MD5.hexdigest( rand(100000000).to_s + Time.now.to_s)
  end

  def new_widget
    Widget.new(:user => self, :company_id => self.company_id, :collapsed => 0, :configured => true)
  end

  def generate_widgets

    old_lang = Localization.lang

    Localization.lang(self.locale || 'en_US')

    w = new_widget
    w.name =  _("Top Tasks")
    w.widget_type = 0
    w.number = 5
    w.mine = true
    w.order_by = "priority"
    w.column = 0
    w.position = 0
    w.save

    w = new_widget
    w.name = _("Newest Tasks")
    w.widget_type = 0
    w.number = 5
    w.mine = false
    w.order_by = "date"
    w.column = 0
    w.position = 1
    w.save

    w = new_widget
    w.name = _("Open Tasks")
    w.widget_type = 3
    w.number = 7
    w.mine = true
    w.column = 1
    w.position = 0
    w.save

    w = new_widget
    w.name = _("Projects")
    w.widget_type = 1
    w.number = 0
    w.column = 1
    w.position = 1
    w.save

    Localization.lang(old_lang)

  end

  def avatar_url(size=32, secure = false)
    if avatar?
      if size > 25 && File.exist?(avatar_large_path)
        '/users/avatar/'+id.to_s+'?large=1'
      else
        '/users/avatar/'+id.to_s
      end
    elsif email
      if secure
  "https://secure.gravatar.com/avatar.php?gravatar_id=#{Digest::MD5.hexdigest(self.email.downcase)}&rating=PG&size=#{size}"
      else
  "http://www.gravatar.com/avatar.php?gravatar_id=#{Digest::MD5.hexdigest(self.email.downcase)}&rating=PG&size=#{size}"
      end
    end
  end

  # label and value are used for the json formatting used for autocomplete
  def label
    name
  end
  alias_method :value, :label
  alias_method :display_name, :label

  def display_login
    name + " / " + (customer.nil? ? company.name : customer.name)
  end

  def can?(project, perm)
    return true if project.nil?

    @perm_cache ||= {}
    unless @perm_cache[project.id]
      @perm_cache[project.id] ||= {}
      self.project_permissions.each do | p |
        @perm_cache[p.project_id] ||= {}
        ProjectPermission.permissions.each do |p_perm|
          @perm_cache[p.project_id][p_perm] = p.can?(p_perm)
        end
      end
    end

    (@perm_cache[project.id][perm] || false)
  end

  def is_leader_for?(project)
    return self.id == project.leader_id
  end



  def can_all?(projects, perm)
    projects.all? {|p| can?(p, perm)}
  end

  def can_any?(project, perm)
    projects.any? {|p| can?(p, perm)}
  end

  def admin?
    self.admin > 0
  end

  ###
  # Returns true if this user is allowed to view the clients section
  # of the website.
  ###
  def can_view_clients?
    self.admin? or self.read_clients?
  end

  # Returns true if this user is allowed to view the given task.
  def can_view_task?(task)
    ! Task.accessed_by(self).find_by_id(task).nil?
  end

  # Returns a fragment of sql to restrict tasks to only the ones this
  # user can see
  def user_tasks_sql
    res = []
    if self.projects.any?
      res << "tasks.project_id in (#{ all_project_ids.join(",") })"
    end

    res << "task_users.user_id = #{ self.id }"

    res = res.join(" or ")
    return "(#{ res })"
  end

 # Returns an array of all milestone this user has access to
  # (through projects).
  # If options is passed, those options will be passed to the find.
  def milestones
    company.milestones.where([ "projects.id in (?)", all_project_ids ]).includes(:project).order("lower(milestones.name)")
  end

  def tz
    @tz ||= TZInfo::Timezone.get(self.time_zone)
  end

  # Get date formatter in a form suitable for jQuery-UI
  def dateFormat
    return 'mm/dd/yy' if self.date_format == '%m/%d/%Y'
    return 'dd/mm/yy' if self.date_format == '%d/%m/%Y'
    return 'yy/mm/dd' if self.date_format == '%Y-%m-%d'
  end

  def to_s
    str = [ name ]
    str << "(#{ customer.name })" if customer

    str.join(" ")
  end

  def private_task_filters
    task_filters.visible.where("user_id = ?", self.id)
  end

  def shared_task_filters
    company.task_filters.shared.visible.where("user_id != ?", self.id)
  end

  # return as a string the default email address for this user
  # return nil if this user has no default email address
  def email
    email_addresses.detect { |pv| pv.default }.try(:email)
  end

  alias_method :primary_email, :email

  def email=(new_email)
    if new_record? || email_addresses.size == 0 || email_addresses.detect{|pv| pv.default }.blank?
      email_addresses.build(:email => new_email, :default => true)
    else
      email_addresses.detect{ |pv| pv.default }.attributes= {:email => new_email}
    end
  end

  def get_working_hours_for(date)
    weekly_working_hours = working_hours.split '|'
    day_of_the_week = date.wday    
    weekly_working_hours[day_of_the_week].to_f
  end

  def working_hours_to_weekly_hash
    weekly_hash = {}
    weekly_working_hours = working_hours.split '|'
    week_days = [:monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday]

    week_days.each_with_index do |week_day, index| 
      weekly_hash[week_day] = weekly_working_hours[index]
    end

    weekly_hash
  end

  protected

  def password_required?
    new_record? || !password.nil? || !password_confirmation.nil?
  end

private
  
  def reject_destroy_if_exist
    [:work_logs].each do |association|
      errors.add(:base, "The user has the #{association.to_s.humanize}, please remove them first or deactivate user.") unless eval("#{association}.count").zero?
    end
    if errors.count.zero?
      ActiveRecord::Base.connection.execute("UPDATE tasks set creator_id = NULL WHERE company_id = #{self.company_id} AND creator_id = #{self.id}")
      return true
    else
      return false
    end
  end

  # Sets the date time format for this user to a sensible default
  # if it hasn't already been set
  def set_date_time_formats
    first_user = company.users.detect { |u| u != self }

    if first_user and first_user.time_format and first_user.date_format
      self.time_format = first_user.time_format
      self.date_format = first_user.date_format
    else
      self.date_format = "%d/%m/%Y"
      self.time_format = "%H:%M"
    end
  end
end
