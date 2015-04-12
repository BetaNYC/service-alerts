class Delay < ActiveRecord::Base
  def self.update_active_false_for_ended
    Delay.where(active: true).where.not(end_time: $mta_current_time)
         .update_all(active: false)
  end

  def self.create_or_update alert_nk
    data = self.extract_data alert_nk
    alert = Delay.find_by(active: true, original_html: data[:original_html]) ||
            Delay.create(data)

    alert.update end_time: $mta_current_time,
                 duration: self.calculate_duration(alert)
  end

  def self.calculate_duration alert
    if alert.start_time.nil?
      return nil
    else
      duration_seconds = $mta_current_time.to_time - alert.start_time.to_time
      return duration_minutes = (duration_seconds / 60).to_i
    end
  end

  def self.extract_data alert_nk
    alert_text = alert_nk.inner_text.sub("Allow additional travel time.", '')

    standard_delay = /Posted: (.+) Due to (.+) (between.+?|at.+?),.(.+).(?:train service is|trains are) running with delays(.*)\./
    residual_delay = /Posted: (.+) Following an earlier incident at (.+),.(.+).trains? service has resumed with residual delays(.*)\./

    data = case alert_text
    when standard_delay
      {
        start_time: Alert.process_start_time("#$1"),
        incident_type: "#$2",
        incident_location: "#$3",
        affected_lines: "#$4#$5"
      }
    when residual_delay
      {
        start_time: Alert.process_start_time("#$1"),
        incident_type: "residual delay",
        incident_location: "#$2",
        affected_lines: "#$3#$4"
      }
    else
      {}
    end

    data[:original_html] = alert_nk.css('body').inner_html
    data[:active] = true
    data
  end
end