# tin-can

tin-can allows you to do pub/sub between apps using redis.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'tin-can'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install tin-can

## Usage

First create a initializer on config/tin_can.rb

```
TinCan.subscribe 'event_name', to: MyEventController, action: :my_action
TinCan.start
```

Then create an EventController: app/event_controllers/my_event_controller.rb
```
class MyEventController < TinCan::EventController
  def my_action
    # awesome stuff here!
  end
end
```
Every time the TinCan receives an event, the TinCan::EventHandler will match and route to the desired event controller and action.

### To send events
```
TinCan::Event.new(channel_name, payload)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/tin-can. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

