# namespace 'tin_can' do
#   require 'tin_can'


#   desc 'Start the tin-can handler'
#   task start: :environment do
#     require "#{Rails.root}/config/tin_can_routes"
#     Rails.logger       = Logger.new(Rails.root.join('log', 'tin-can.log'))
#     Rails.logger.level = Logger.const_get((ENV['LOG_LEVEL'] || 'info').upcase)

#     if ENV['BACKGROUND']
#       Process.daemon(true, true)
#     end
#     pidfile = ENV['PIDFILE'] || 'tmp/pids/tin-can.pid'
#     File.open(pidfile, 'w') { |f| f << Process.pid }

#     Signal.trap('TERM') { abort }

#     Rails.logger.info "Starting TinCan daemon with pid #{Process.pid} and pidfile #{pidfile}"

#     TinCan.start
#   end

# end
