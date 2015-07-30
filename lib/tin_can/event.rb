require 'json'

module TinCan
  class Event
    attr_reader :channel, :payload
    def initialize(channel, payload)
      @channel = channel
      @payload = payload.to_json
    end

    def fire!
      receivers = TinCan.redis.publish channel, payload
      persist if receivers == 0
    end

    def persist
      # code to persist to redis (see rpush)
    end

  end
end
