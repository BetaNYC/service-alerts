require 'open-uri'
require 'date'

class Alert < ActiveRecord::Base

  def self.get_data

    puts "get data now"

    page = self.download_page
    lines = self.find_lines page

    lines.each do |line|
      puts self.line_data line
    end
  end

  private

    def self.download_page
      # For testing purposes, we get a saved serviceData file.
      return Nokogiri::HTML(open("../research/2015-02-22-08-42-01.xml"))

      url = "http://web.mta.info/status/serviceStatus.txt"
      begin
        # page = Nokogiri::HTML(open(url))
      rescue
        puts "Exception #{e}"
        puts "Unable to fetch #{url}"
      end
    end

    def self.find_lines page
      page.css('line')
    end

    def self.line_data line
      date = line.css('date').inner_text
      time = line.css('time').inner_text

      {
        name: line.css('name').inner_text,
        status: line.css('status').inner_text,
        date: "#{date} #{time}"
      }
    end

    def self.clean_html_page line
      regex = /<\/*br\/*>|<\/*b>|<\/*i>|<\/*strong>|<\/*font.*?>|<\/*u>/
      clean_html = line.css('text').inner_text.gsub(regex, '')
      Nokogiri::HTML(clean_html)
    end
end