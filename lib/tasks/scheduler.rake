desc "Scrapes the MTA feed for alerts"
task :scrape => :environment do
  puts "Updating alerts..."
  page = Feed.get_page
  Feed.new page
  puts "Alerts updated."
end
