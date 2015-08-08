namespace 'tin-can' do
  require 'tin_can'


  desc 'Start the tin-can handler'
  task start: :environment do
    start
  end
  desc 'Stop the tin-can handler'
  task stop: :environment do
    stop
  end
  desc 'Restart the tin-can handler'
  task restart: :environment do
    puts "Restarting TinCan"
    stop
    start
  end

end


def start
  require "#{Rails.root}/config/tin_can_routes"
  Rails.logger       = Logger.new(Rails.root.join('log', 'tin-can.log'))
  Rails.logger.level = Logger.const_get((ENV['LOG_LEVEL'] || 'info').upcase)
  begin
    pidfile = ENV['PIDFILE'] || 'tmp/pids/tin-can.pid'
    # check if the pidfile exists
    if File.exists?(pidfile)
      # if true, just read the pid
      pid = File.read(pidfile).to_i
    else
      # if false, try to use the system to find an instance of tin-can running
      # and get its PID.
      pid = `pgrep -f "rake tin-can:start"`.to_i

      # pid will be == 0 if no process is found
      if pid != 0
        # if pid is not zero, the process is running, but
        # there is no pid file, so let's create it.
        File.open(pidfile, 'w') { |f| f << pid }
      end
    end
    # again, if no process is running, PID is == 0. Because
    # Process.getpgid( 0 ) will return something we don't want,
    # lets not even try if pid == 0
    already_running = Process.getpgid( pid ) unless pid == 0 rescue nil
    if already_running
      puts "A TinCan handler is already running with PID: #{pid}."
      return
    else
      # run in foreground if FOREGROUND env variable
      # is set.
      unless ENV['FOREGROUND']
        puts 'Starting TinCan...'
        Process.daemon(true, true)
        # supress output
        $stderr.reopen('/dev/null', 'a')
        $stdout.reopen($stderr)
      end
      # write pid file
      File.open(pidfile, 'w') { |f| f << Process.pid }
      # stop if ctrl/cmd+c
      Signal.trap('TERM') { abort }

      Rails.logger.info "Starting TinCan daemon with pid #{Process.pid} and pidfile #{pidfile}"

      TinCan.start
    end
  end
end

def stop
  pidfile = ENV['PIDFILE'] || 'tmp/pids/tin-can.pid'
  if File.exists?(pidfile)
    pid = File.read(pidfile).to_i
  elsif !(pid = `pgrep -f "rake tin-can:start"`).blank?
    pid = pid.to_i
  else
    puts "Could not find any instances of TinCan running."
    return
  end
  begin
    puts "Stopping TinCan with PID: #{pid}..."
    if Process.kill('QUIT', pid)
      puts "Removing PID file #{pidfile}..."
      File.delete(pidfile)
      puts "TinCan stopped."
    end
  rescue Errno::ESRCH
    # The PID was not wunning.
    puts "TinCan was not running."
    puts "Removing stale PID file #{pidfile}..."
    File.delete(pidfile)

  end
end
