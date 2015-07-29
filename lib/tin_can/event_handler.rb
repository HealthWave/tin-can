require 'daemons'

module TinCan
  class EventHandler
    PID_FILE_NAME = 'tin_can.pid'
    attr_reader :events, :pid

    def initialize(events)
      @events = events
    end

    def restart
      self.class.stop
      self.start
    end

    def self.stop working_dir=nil
      pid_dir = File.join(working_dir || './', 'tmp', 'pids')
      filepath =  File.join("tmp", "proc", PID_FILE_NAME)
      if File.exists?(filepath)
        current_pid = File.open(filepath, 'r').read.chomp
        system "mkdir -p #{pid_dir} > /dev/null"
        system "pgrep #{current_pid} && kill -9 #{current_pid} && rm #{filepath}"
      end

      @pid = nil
    end

    def start backtrace: false, ontop: false, log_output: false
      self.class.stop

      working_dir= defined?(Rails) && Rails.respond_to?(:root) && Rails.root.to_s || Dir.pwd
      Daemons.daemonize(backtrace: backtrace, ontop: ontop, log_output: log_output)

      @pid = Process.pid
      File.open( File.join(working_dir, "tmp/pids/#{PID_FILE_NAME}"), 'w') do |f|
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

          begin
            controller.public_send(action)
          rescue StandardError => e
            puts e.message
            puts e.backtrace
          end
        end
      end
    end
  end

end
