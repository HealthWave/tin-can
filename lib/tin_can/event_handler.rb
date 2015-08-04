require 'daemons'

module TinCan
  class EventHandler
    attr_reader :events

    def initialize(events)
      @events = events
    end

    def start
      log_msg = "Subscribing to events #{@events}"
      puts log_msg
      Rails.logger.info log_msg
      TinCan.redis.subscribe(*@events) do |on|
        on.message do |channel, msg|
          log_msg = "Received message with\n\tchannel:\t#{channel}\n\tmessage:\t#{msg}"
          puts log_msg
          Rails.logger.info log_msg

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
            Rails.logger.info e.message
            Rails.logger.info e.backtrace
          end
        end
      end
    end

  end
end
