namespace 'tin_can' do
  require 'tin_can'


  desc 'Start the tin-can handler'
  task start: :environment do
    require "#{Rails.root}/config/tin_can_routes"
    Rails.logger       = Logger.new(Rails.root.join('log', 'daemon.log'))
    Rails.logger.level = Logger.const_get((ENV['LOG_LEVEL'] || 'info').upcase)

    if ENV['BACKGROUND']
      Process.daemon(true, true)
    end

    if ENV['PIDFILE']
      File.open(ENV['PIDFILE'], 'w') { |f| f << Process.pid }
    end

    Signal.trap('TERM') { abort }

    Rails.logger.info "Start daemon..."

    loop do
      TinCan.start

      sleep ENV['INTERVAL'] || 1
    end
  end
  desc 'Stop the daemon'
  task stop: :environment do

  end
end
