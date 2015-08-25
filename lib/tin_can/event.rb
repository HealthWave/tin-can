require 'json'

module TinCan
  class Event
    @@default_error_fallback_proc = nil

    def self.default_fallback &b
      if b
        @@default_error_fallback_proc = b
      end
      @@default_error_fallback_proc
    end


    attr_reader :channel, :payload

    def initialize(channel, payload)
      @channel = channel
      @payload = payload.to_json
    end


    def broadcast! &b
      receivers = TinCan.redis.publish channel, payload
      return true unless receivers == 0

      if block_given?
        yield self
      elsif @@default_error_fallback_proc
        @@default_error_fallback_proc.call self
      end

      return false
    end

  end
end
