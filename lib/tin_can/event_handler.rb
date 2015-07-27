require 'daemons'

module TinCan
  class EventHandler
    PID_FILE_NAME = 'tin_can.pid'
    attr_reader :events, :pid

    def initialize(events)
      @events = events
      @working_dir = nil
    end

    def restart
      self.stop
      self.start
    end

    def stop
      pid_dir = File.join(@working_dir || './', 'tmp', 'pids')
      system "mkdir -p #{pid_dir} > /dev/null"
      system "kill -9 $(cat #{pid_dir}/#{PID_FILE_NAME}) > /dev/null"
      system "rm  #{pid_dir}/#{PID_FILE_NAME} > /dev/null"

      @pid = nil
    end

    def start backtrace: false, ontop: false, log_output: false
      self.stop

      @working_dir= Dir.pwd
      Daemons.daemonize(backtrace: backtrace, ontop: ontop, log_output: log_output)

      @pid = Process.pid
      File.open( File.join(@working_dir, "tmp/pids/#{PID_FILE_NAME}"), 'w') do |f|
        f.puts @pid
      end

      TinCan.redis.subscribe(*@events) do |on|
        on.message do |channel, msg|
          puts "Recieved message with\n\tchannel:\t#{channel}\n\tmessage:\t#{msg}"

          controller_klass, action = TinCan.routes[channel]

          raise TinCan::EventController::ControllerNotDefined.new unless controller_klass
          raise TinCan::EventController::ActionMissing.new(controller_klass.name) unless action

          controller = controller_klass.new(msg)

          raise TinCan::EventController::ActionNotDefined.new(action, controller_klass.name) unless controller.public_methods(false).include?(action.to_sym)

          controller.public_send(action)
        end
      end
    rescue Redis::BaseConnectionError => error
      puts "#{error}, retrying in 1s"

      if foreground
        run!
      else
        @pid = Thread.new { run! }
      end
    end
  end

end
