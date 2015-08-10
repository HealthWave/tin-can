# tin-can
[![Circle CI](https://circleci.com/gh/HealthWave/tin-can.svg?style=svg)](https://circleci.com/gh/HealthWave/tin-can)
[![Code Climate](https://codeclimate.com/github/HealthWave/tin-can/badges/gpa.svg)](https://codeclimate.com/github/HealthWave/tin-can)
[![Test Coverage](https://codeclimate.com/github/HealthWave/tin-can/badges/coverage.svg)](https://codeclimate.com/github/HealthWave/tin-can/coverage)

tin-can is a Rails gem that allows you to do pub/sub between apps using redis.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'tin-can'
```

And then execute:

    $ bundle install


## Listening to events
The steps below should be applied on all apps that are receiving messages.

First create a initializer on config/tin_can_routes.rb

```ruby
TinCan.routes do
  route 'event_name', to: MyEventController, action: :my_action
end
```

Then create an EventController: app/event_controllers/my_event_controller.rb
```ruby
class MyEventController < TinCan::EventController
  def my_action
    # awesome stuff here!
  end
end
```

Now create a rake task to start the TinCan Handler, for example:
```ruby
namespace 'tin-can' do
  require 'tin_can'


  desc 'Start the tin-can handler'
  task start: :environment do
    start
  end
  desc 'Stop the tin-can handler'
  task stop: :environment do
    stop
  end
  desc 'Restart the tin-can handler'
  task restart: :environment do
    puts "Restarting TinCan"
    stop
    system "rake tin-can:start"
  end

end


def start
  require "#{Rails.root}/config/tin_can_routes"
  Rails.logger       = Logger.new(Rails.root.join('log', 'tin-can.log'))
  Rails.logger.level = Logger.const_get((ENV['LOG_LEVEL'] || 'info').upcase)
  begin
    pidfile = ENV['PIDFILE'] || 'tmp/pids/tin-can.pid'
    # check if the pidfile exists
    if File.exists?(pidfile)
      # if true, just read the pid
      pid = File.read(pidfile).to_i
    else
      # if false, try to use the system to find an instance of tin-can running
      # and get its PID.
      pid = `pgrep -f "rake tin-can:start"`.to_i

      # pid will be == 0 if no process is found
      if pid != 0
        # if pid is not zero, the process is running, but
        # there is no pid file, so let's create it.
        File.open(pidfile, 'w') { |f| f << pid }
      end
    end
    # again, if no process is running, PID is == 0. Because
    # Process.getpgid( 0 ) will return something we don't want,
    # lets not even try if pid == 0
    already_running = Process.getpgid( pid ) unless pid == 0 rescue nil
    if already_running
      puts "A TinCan handler is already running with PID: #{pid}."
      return
    else
      # run in foreground if FOREGROUND env variable
      # is set.
      unless ENV['FOREGROUND']
        puts 'Starting TinCan...'
        Process.daemon(true, true)
        # supress output
        $stderr.reopen('/dev/null', 'a')
        $stdout.reopen($stderr)
      end
      # write pid file
      File.open(pidfile, 'w') { |f| f << Process.pid }
      # stop if ctrl/cmd+c
      Signal.trap('TERM') { abort }

      Rails.logger.info "Starting TinCan daemon with pid #{Process.pid} and pidfile #{pidfile}"

      TinCan.start
    end
  end
end

def stop
  pidfile = ENV['PIDFILE'] || 'tmp/pids/tin-can.pid'
  if File.exists?(pidfile)
    pid = File.read(pidfile).to_i
  elsif !(pid = `pgrep -f "rake tin-can:start"`).blank?
    pid = pid.to_i
  else
    puts "Could not find any instances of TinCan running."
    return
  end
  begin
    puts "Stopping TinCan with PID: #{pid}..."
    if Process.kill('QUIT', pid)
      puts "Removing PID file #{pidfile}..."
      File.delete(pidfile)
      puts "TinCan stopped."
    end
  rescue Errno::ESRCH
    # The PID was not wunning.
    puts "TinCan was not running."
    puts "Removing stale PID file #{pidfile}..."
    File.delete(pidfile)

  end
end

```
And start by doing:
```
rake tin-can:start
```
To stop:
```ruby
rake tin-can:stop
```
Restart:
```ruby
rake tin-can:restart
```
To run TinCan on foreground, do:
```ruby
FOREGROUND=true rake tin-can:start
```
Every time the TinCan receives an event, the TinCan::EventHandler will match and route to the desired event controller and action.

## Sending events
Sending an event is as easy as
```ruby
# payload must be an object that responds to to_json
payload = {message: 'This is a message', wharever: true}
event = TinCan::Event.new('event_name', payload)
event.broadcast!
```
If you broadcast an event when nobody is listening, the event will be lost. You can handle this case by bassing a block to the broadcast! method:
```ruby
TinCan::Event.new(channel_name, payload).broadcast! do |event|
  # Saves the event to resque
  Resque.enqueue( EventRetry, event.channel, event.payload )
end


## TODO
- Decouple from Rails
  - Use another logger


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/tin-can. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

