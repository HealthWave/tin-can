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

Now create a rake task to start the TinCan Handler. Here is an example:
```ruby
namespace 'tin-can' do
  require 'tin_can'


  desc 'Start the tin-can handler'
  task start: :environment do
    TinCan.start
  end
  desc 'Stop the tin-can handler'
  task stop: :environment do
    TinCan.stop
  end
  desc 'Check if the handler is running'
  task status: :environment do
    TinCan.status
  end
  desc 'Restart the tin-can handler'
  task restart: :environment do
    puts "Restarting TinCan"
    TinCan.stop
    system "rake tin-can:start"
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
```

## TODO
- Add option to use RPUSH and BLPOP instead of pub/sub.
- Add option to run as a separate thread inside Rails.
- Add start/stop/status rake task to gem
- Test usage outside Rails
- Refactor a bit



## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/tin-can. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

