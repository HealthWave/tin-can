require 'redis'
require "tin_can/version"
require "tin_can/event"
require "tin_can/event_controller"
require "tin_can/event_handler"

module TinCan
  @@redis_host = nil
  @@redis_port = nil

  def self.config redis_host: 'localhost', redis_port: 6379, &b
    @@redis_host = redis_host
    @@redis_port = redis_port
    b.call(@@redis_host, @@redis_port) if block_given?
  end

  # {
  #   "health_wave.store_created" => {MyEventController => :store_created}
  # }
  def self.subscribe(channel, to: TinCan::EventController, action:)
    @@routes ||= {}
    @@routes[channel] = [ to,  action ]
  end

  # TODO PID?
  def self.start
    TinCan::EventHandler.new(@@routes.keys).start
  end

  def self.redis
    return $redis if $redis
    raise  "Need to provid redis host and port to ::config" unless @@redis_port && @@redis_host


    $redis = Redis.new(:host => $redis_host, :port => $redis_port, :thread_safe => true)
  end
end

require 'tin_can/errors'
