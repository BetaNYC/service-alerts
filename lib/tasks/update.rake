desc "Rebuild alerts from raw feed"
task :rebuild_alerts => :environment do
  puts "Deleting delays"
  Delay.delete_all

  RawFeed.find_each do |feed_record|
    puts "Scanning #{feed_record[:id]} from #{feed_record[:mta_current_time]}"
    Feed.new feed_record[:feed], false
  end
end