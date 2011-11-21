class EmailDelivery < ActiveRecord::Base
  belongs_to :work_log
  belongs_to :user

  # this method will send all undelivered work log notifications
  # it should be called regularly in production environment
  def EmailDelivery.cron
    deliveries=EmailDelivery.where(:status=>'queued').includes(:work_log)
    logger.info "EmailDelivery.cron: trying to delivery #{deliveries.size} records"
    deliveries.each{|delivery|
      logger.info "EmailDelivery.cron: trying to send work log: #{delivery.work_log.inspect}"
      delivery.deliver
    }
  end

  def username_or_email
    user ? user.name : self.email
  end

  def deliver
    work_log = self.work_log
    if work_log.log_type == EventLog::TASK_CREATED
      Notifications.created(self).deliver
    else
      Notifications.changed(self).deliver
    end
    self.status = 'sent'
    self.save!
  rescue Exception => exc
    logger.error "Failed to send notification delivery##{self.id}. Error : #{exc}"
  end
end


# == Schema Information
#
# Table name: email_deliveries
#
#  id          :integer(4)      not null, primary key
#  work_log_id :integer(4)
#  status      :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#  email       :string(255)
#  user_id     :integer(4)
#

