require 'open-uri'
require 'date'

class Alert
  @@delimiter = '<span class="Title'

  def self.split_alerts line_name, alerts
    split_alerts = alerts.css('body').inner_html.split(@@delimiter)

    split_alerts.each do |alert|
      # When splitting the first element is empty.
      unless alert.empty?
        alert_html = @@delimiter + alert
        alert_nk = Nokogiri::HTML alert_html
        Alert.new alert_nk
      end
    end
  end

  def self.process_start_time time_str
    DateTime.strptime time_str, "%m/%d/%Y %l:%M%p"
  end


  def initialize alert_nk
    alert_type = alert_nk.css('span').first.inner_text

    case alert_type
    when "Delays" then Delay.create_or_update alert_nk
    when "Planned Work"
      # TODO
    when "Service Change"
      # TODO
    end
  end
end
