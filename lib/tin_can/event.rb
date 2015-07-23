module TinCan
  class Event
    attr_reader :channel, :payload
    def initialize(channel, payload)
      @channel = channel
      @payload = payload.to_json
    end

    def fire!
      self.class.redis.publish channel, payload
    end

  end
end
