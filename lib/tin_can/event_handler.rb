require 'daemons'

module TinCan
  class EventHandler
    attr_reader :events, :pid

    def initialize(events)
      @events = events
    end

    def restart
      self.stop
      self.start
    end

    def stop
      system 'mkdir -p ./tmp/pids/ > /dev/null'
      system 'kill -9 $(cat ./tmp/pids/tin_can.pid) > /dev/null'
      system 'rm  ./tmp/pids/tin_can.pid > /dev/null'

      @pid = nil
    end

    def start backtrace: true, ontop: true, log_output: true
      self.stop

      Daemons.daemonize(backtrace: backtrace, ontop: ontop, log_output: log_output)

      File.open("./tmp/pids/tin_can.pid", 'w') do |f|
        f.puts Process.pid
      end

      TinCan.redis.subscribe(*@events) do |on|
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

      if foreground
        run!
      else
        @pid = Thread.new { run! }
      end
    end
  end

end
