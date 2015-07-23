module TinCan
  class Event
    attr_reader :channel, :payload
    def initialize(channel, payload)
      @channel = channel

      case payload
      when String
        @payload = payload
      when Hash
        @payload = payload.to_json
      end
    end

    def fire!
      self.class.redis.publish channel, payload
    end

  end
end
