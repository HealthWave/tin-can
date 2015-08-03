require 'tin_can'
require 'rails'

module TinCan
  class Railtie < Rails::Railtie
    railtie_name :tin_can

    rake_tasks do
      load 'tasks/tin_can.rake'
    end
  end
end
