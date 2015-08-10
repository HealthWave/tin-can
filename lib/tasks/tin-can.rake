namespace 'tin-can' do
  require 'tin_can'


  desc 'Start the tin-can handler'
  task start: :environment do
    TinCan.start
  end
  desc 'Stop the tin-can handler'
  task stop: :environment do
    TinCan.stop
  end
  desc 'Check if the handler is running'
  task status: :environment do
    TinCan.status
  end
  desc 'Restart the tin-can handler'
  task restart: :environment do
    puts "Restarting TinCan"
    TinCan.stop
    system "rake tin-can:start"
  end

end
