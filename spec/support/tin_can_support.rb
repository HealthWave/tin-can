require 'tin_can'

class MyEventController < TinCan::EventController
  def someaction1
    return 'someaction1'
  end
  def someaction2
    return 'someaction1'
  end
end
TinCan.routes do
  route 'my_event1', to: MyEventController, action: :some_action1
  route 'my_event2', to: MyEventController, action: :some_action2
  # non defined action
  route 'my_event3', to: MyEventController, action: :some_action3
end
