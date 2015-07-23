require 'redis'
require "tin_can/version"
require "tin_can/event"
require "tin_can/event_controller"
require "tin_can/event_handler"

module TinCan
  @@routes = nil
  @@redis_host = nil
  @@redis_port = nil

  def self.routes
    @@routes
  end

  def self.config redis_host: 'localhost', redis_port: 6379
    @@redis_host = redis_host
    @@redis_port = redis_port
  end

  # {
  #   "health_wave.store_created" => {MyEventController => :store_created}
  # }
  def self.subscribe(channel, to: TinCan::EventController, action:)
    @@routes ||= {}
    @@routes[channel] = [ to,  action ]
  end

  def self.start
    raise TinCan::NotConfigured.new unless routes
    TinCan::EventHandler.new(routes.keys).start
  end

  def self.redis
    return $redis if $redis
    raise  "Need to provid redis host and port to ::config" unless @@redis_port && @@redis_host

    $redis = Redis.new(:host => $redis_host, :port => $redis_port, :thread_safe => true)
  end
end

require 'tin_can/errors'
