module TinCan
  class EventHandler
    attr_reader :events

    def initialize(events)
      @events = events
    end

    def start
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

  end
end
