module TinCan
  class EventController
    attr_reader :params
    def initialize(object)
      @params = JSON.parse object, symbolize_names: true
    end
  end
end
