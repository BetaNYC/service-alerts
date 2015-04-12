require 'open-uri'

class Feed

  def self.get_page url="http://web.mta.info/status/serviceStatus.txt"
    open url
  end

  def initialize page
    @doc = parse_page page
    $mta_current_time = mta_current_time

    # FIXME: This feels very wrong. I'd rather that this used the Feed model.
    RawFeed.create feed: @doc.inner_html, mta_current_time: $mta_current_time

    # If the feed's timestamp is equal to end_time of the existing active delays
    # then the feed hasn't been updated since we last checked it.
    active_delay = Delay.find_by(active: true)
    if active_delay.nil? || active_delay.end_time != $mta_current_time
      lines = select_lines
      create_alerts_for_lines lines

      # Any alerts that have an end_time that is before the current_time, but
      # active: true, are residuals from the last iteration and are set to
      # false.
      Delay.update_active_false_for_ended
    end
  end

  def mta_current_time
    time_str = @doc.xpath('service/timestamp').inner_text
    DateTime.strptime time_str, "%m/%d/%Y %l:%M:%S %p"
  end

  def parse_page page
    Nokogiri::XML page
  end

  def select_lines
    all_lines = @doc.xpath('service/subway/line')
    all_lines.select do |line|
      has_alert?(line)
    end
  end

  # Trains with "GOOD SERVICE" don't have alerts
  def has_alert? line
    status = line.css('status').inner_text.strip
    status != "GOOD SERVICE"
  end

  # The HTML in the `text` field of the XML is horrifically invalid, this helps.
  def fix_html line
    # Escaped characters (&gt; etc.) are automatically unescaped by Nokogiri.
    raw_text = line.css('text').inner_text
    regex = /<\/*br\/*>|<\/*b>|<\/*i>|<\/*u>|<\/*strong>|<\/*font.*?>/
    formatted_text = raw_text.gsub(regex, '').gsub('&nbsp;', ' ')
                              .gsub(/\s{2,}/, ' ')
    Nokogiri::HTML formatted_text
  end

  def create_alerts_for_lines lines
    feed = self
    lines.each do |line|
      Alert.split_alerts(
        line.css('name').inner_text,
        fix_html(line)
      )
    end
  end


end