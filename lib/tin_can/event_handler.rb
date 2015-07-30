require 'daemons'

module TinCan
  class EventHandler
    attr_reader :events

    def initialize(events)
      @events = events
    end

    def start
      puts "subscribing to events #{@events}"
      TinCan.redis.subscribe(*@events) do |on|
        on.message do |channel, msg|
          puts "Received message with\n\tchannel:\t#{channel}\n\tmessage:\t#{msg}"

          controller_klass, action = TinCan.routes[channel]

          raise TinCan::EventController::ControllerNotDefined.new unless controller_klass
          raise TinCan::EventController::ActionMissing.new(controller_klass.name) unless action

          controller = controller_klass.new(msg)

          raise TinCan::EventController::ActionNotDefined.new(action, controller_klass.name) unless controller.public_methods(false).include?(action.to_sym)

          controller.public_send(action)
        end
      end
    end

  end
end
