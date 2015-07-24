module TinCan
  class EventHandler
    attr_reader :events, :thread

    def initialize(events)
      @events = events
    end

    def restart
      self.stop
      self.start
    end

    def stop
      thread.kill if thread
      @thread = nil
    end

    def start foreground: false
      self.stop

      if foreground
        run!
      else
        @thread = Thread.new { run! }
      end
    end

    def run!
      begin
        system "kill -9 $(cat #{root_path}/tmp/pids/tin_can.pid)"
        options = { :backtrace  => true, :ontop      => true, :log_output => true }

        # File.open("#{root_path}/tmp/pids/tin_can.pid", 'w') do |f|
        #   f.puts Process.pid
        # end

        self.redis.subscribe(*@events) do |on|
          on.message do |channel, msg|
            puts "Recieved message with\n\tchannel:\t#{channel}\n\tmessage:\t#{msg}"

            controller_klass, action = TinCan.routes[channel]

            raise TinCan::EventController::ControllerNotDefined.new unless controller_klass
            raise TinCan::EventController::ActionMissing.new(controller_klass.name) unless action

            controller = controller_klass.new(msg)

            raise TinCan::EventController::ActionNotDefined.new(action, controller_klass.name) unless controller.public_methods(false).include(action)

            controller.public_send(action)
          end
        end
      rescue Redis::BaseConnectionError => error
        puts "#{error}, retrying in 1s"
      ensure
        self.redis.close
      end
    end

  end
end
