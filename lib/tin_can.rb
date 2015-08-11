require 'redis'

require "tin_can/version"
require "tin_can/event"
require "tin_can/event_controller"
require "tin_can/event_handler"

module TinCan
  @@handler = nil
  @@routes = nil
  @@redis_host = 'localhost'
  @@redis_port = 6379
  @@rails = false

  def self.rails
    @@rails
  end

  def self.rails=value
    @@rails = value
  end

  def self.logger=loggr
    @@logger = loggr
  end
  def self.logger
    @@logger ||= Logger.new($stdout).tap do |log|
      log.progname = self.name
    end
  end

  def self.routes &block
    if block_given?
      instance_eval &block
    end
    @@routes
  end


  def self.config redis_host: 'localhost', redis_port: 6379
    @@redis_host = redis_host
    @@redis_port = redis_port
  end

  # {
  #   "health_wave.store_created" => {MyEventController => :store_created}
  # }
  def self.route(channel, to: TinCan::EventController, action:)
    @@routes ||= {}
    @@routes[channel] = [ to,  action ]
  end

  def self.start
    TinCan.load_environment
    raise TinCan::NotConfigured.new unless routes
    puts "Starting TinCan in foreground..." if ENV['FOREGROUND']
    TinCan.logger.info "Starting TinCan Handler with routes #{TinCan.routes}"
    @@handler = TinCan::EventHandler.new(routes.keys)
    @@handler.start(pidfile: ENV['PIDFILE'], foreground: ENV['FOREGROUND'])
  end
  def self.stop
    @@handler = TinCan::EventHandler.new
    @@handler.stop(pidfile: ENV['PIDFILE'])
  end

  def self.status
    @@handler = TinCan::EventHandler.new
    @@handler.status(pidfile: ENV['PIDFILE'])
  end

  def self.redis
    return $redis if $redis
    fail 'Need to provide redis host and port to ::config' unless @@redis_port && @@redis_host

    $redis = Redis.new(host: $redis_host, port: $redis_port, thread_safe: true, driver: :ruby)
  end

  def self.load_environment(file = nil)
    file ||= "."
    require File.expand_path("#{file}/config/tin_can_routes.rb")
    # puts File.expand_path File.dirname(__FILE__)
    if File.directory?(file) && File.exists?(File.expand_path("#{file}/config/environment.rb"))
      require 'rails'
      require File.expand_path("#{file}/config/environment.rb")
      TinCan.rails = true
      if defined?(::Rails) && ::Rails.respond_to?(:application)
        # Rails 3
        ::Rails.application.eager_load!
      elsif defined?(::Rails::Initializer)
        # Rails 2.3
        $rails_rake_task = false
        ::Rails::Initializer.run :load_application_classes
      end
    elsif File.file?(file)
      require File.expand_path(file)
    end
  end
end

require 'tin_can/errors'
