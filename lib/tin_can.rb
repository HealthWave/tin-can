require "tin_can/version"

module TinCan
  def self.config redis_host: 'localhost', redis_port: 6379, &b
    @@redis_host = redis_host
    @@redis_port = redis_port
    b.call(@@redis_host, @@redis_port) if block_given?
  end

  # {
  #   "health_wave.store_created" => {MyEventController => :store_created}
  # }
  def self.subcribe(channel, to: TinCan::Controller, with_method: nil)
    @@routes ||= {}
    @@routes[channel] = [ to,  with_method ]
  end

  # TODO PID?
  def self.start(root_path)
    TinCan::Handler.new.start
  end

  def self.redis
    return $redis if $redis
    raise  "Need to provid redis host and port to ::config" unless @@redis_port && @@redis_host


    $redis = Redis.new(:host => $redis_host, :port => $redis_port, :thread_safe => true)
  end
end
