module TinCan
  class EventController
    attr_reader :params, :logger
    def initialize(object)
      @params = JSON.parse object, symbolize_names: true
    end
    def self.included(child_class)
      child_class.extend Callbacks
      child_class.initialize_callbacks
    end
  end
end
