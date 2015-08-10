module TinCan
  class EventHandler
    attr_reader :events

    def initialize(events)
      @events = events
    end

    def status(pidfile: nil)
      pidfile ||= 'tmp/pids/tin-can.pid'
      pid = read_pidfile(pidfile)
      if pid && already_running?(pid)
        puts "TinCan is running with pid #{pid}."
      else
        puts "TinCan is NOT running."
      end
    end

    def start(pidfile: nil, foreground: false)
      pidfile = set_pid_file


      # check if the pidfile exists
      pid = read_pidfile(pidfile)

      # again, if no process is running, PID is == 0. Because
      # Process.getpgid( 0 ) will return something we don't want,
      # lets not even try if pid == 0
      if already_running?(pid)
        raise TinCan::AlreadyRunning.new(pid)
      else
        # run in foreground if FOREGROUND env variable
        # is set.
        unless foreground

          log_file_path = set_log_file

          daemonize(pidfile, log_file_path)

          set_logger(log_file_path)

          send_output_to_log_file(log_file_path)
        end
        write_pidfile(pidfile, Process.pid)

        # stop if ctrl/cmd+c
        Signal.trap('TERM') { abort }

        subscribe_to_events
      end

    end

    def set_pid_file
      if File.exists?(File.expand_path('./tmp/pids'))
        File.expand_path('./tmp/pids/tin-can.pid')
      else
        File.expand_path('./tin-can.pid')
      end
    end

    def set_log_file
      # sets the log file
      if File.exists?(File.expand_path('./log'))
        File.expand_path('./log/tin-can.log')
      else
        File.expand_path('./tin-can.log')
      end
    end

    def daemonize(pidfile, log_file_path)
      puts "Starting TinCan daemon:\n- PID #{Process.pid}\n- PID file #{pidfile}\n- Log File #{log_file_path}"
      Process.daemon(true, true)
    end

    def set_logger(log_file_path)
      # Assign a logger
      TinCan.logger = Logger.new(log_file_path, 'weekly').tap do |log|
        log.progname = 'TinCan'
      end
    end

    def send_output_to_log_file(log_file_path)
      # send all output to the log file
      log_file = File.new(log_file_path)
      $stderr.reopen(log_file, 'a')
      $stdout.reopen($stderr)
      $stderr.sync = true
      $stdout.sync = true
    end

    def write_pidfile(pidfile, pid)
      # write pid file
        File.open(pidfile, 'w') { |f| f << pid }
    end


    def subscribe_to_events
      TinCan.logger.info "Subscribing to events #{@events}"
      TinCan.redis.subscribe(*@events) do |on|
        on.message do |channel, msg|
          process_message msg, channel
        end
      end
    end

    def process_message msg, channel
      TinCan.logger.info "Received message with\n\tchannel:\t#{channel}\n\tmessage:\t#{msg}"
      controller_klass, action = TinCan.routes[channel]

      raise TinCan::EventController::ControllerNotDefined.new unless controller_klass
      raise TinCan::EventController::ActionMissing.new(controller_klass.name) unless action

      controller = controller_klass.new(msg)

      raise TinCan::EventController::ActionNotDefined.new(action, controller_klass.name) unless controller.public_methods(false).include?(action.to_sym)

      begin
        controller.public_send(action)
      rescue StandardError => e

        TinCan.logger.info e.message
        TinCan.logger.info e.backtrace
      end
    end

    def stop(pidfile: nil)
      pidfile ||= 'tmp/pids/tin-can.pid'
      pid = read_pidfile(pidfile)
      unless pid && already_running?(pid)
        puts "Could not find any instances of TinCan running."
        return false
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

    def already_running?(pid)
      Process.getpgid( pid ) unless pid == 0 rescue nil
    end

    def read_pidfile(pidfile)
      if File.exists?(pidfile)
        File.read(pidfile).to_i
      elsif (!(pid = `pgrep -f "rake tin-can:start"`).blank? rescue nil)
        write_pidfile(pidfile, pid) unless pid == 0
        pid.to_i
      else
        false
      end
    end

  end
end
