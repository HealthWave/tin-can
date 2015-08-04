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
namespace 'tin_can' do
  require 'tin_can'


  desc 'Start the tin-can handler'
  task start: :environment do
    require "#{Rails.root}/config/tin_can_routes"
    Rails.logger       = Logger.new(Rails.root.join('log', 'tin-can.log'))
    Rails.logger.level = Logger.const_get((ENV['LOG_LEVEL'] || 'info').upcase)

    if ENV['BACKGROUND']
      Process.daemon(true, true)
    end
    pidfile = ENV['PIDFILE'] || 'tmp/pids/tin-can.pid'
    File.open(pidfile, 'w') { |f| f << Process.pid }

    Signal.trap('TERM') { abort }

    Rails.logger.info "Starting TinCan daemon with pid #{Process.pid} and pidfile #{pidfile}"

    TinCan.start
  end

end
```
And start by doing:
```
BACKGROUND=yes rake tin_can:start
```

Every time the TinCan receives an event, the TinCan::EventHandler will match and route to the desired event controller and action.

## Sending events
Sending an event is as easy as
```ruby
event = TinCan::Event.new(channel_name, payload)
event.broadcast!
```
If you broadcast an event when nobody is listening, the event will be lost. You can handle this case by bassing a block to the broadcast! method:
```ruby
TinCan::Event.new(channel_name, payload).broadcast! do |event|
  # Saves the event to resque
  Resque.enqueue( EventRetry, event.channel, event.payload )
end


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/tin-can. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

