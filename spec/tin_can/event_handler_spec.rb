require 'spec_helper'
require 'byebug'
describe TinCan::EventHandler do
  let(:events) { ['my_event1', 'my_event2'] }
  let(:event_handler) { described_class.new(events) }
  let(:redis) { double("Redis") }

  describe '#initialize' do
    it 'sets the events to which the handler will listen to' do
      expect( event_handler.events ).to eq events
    end
  end

  describe "#start!" do
    context 'code' do
      it 'raises error if action not defined' do
        controller_klass, action = TinCan.routes['my_event3']
        expect{event_handler.process_message({message: 'ok'}.to_json, 'my_event3')}.to raise_error#(TinCan::EventController::ActionNotDefined.new action, controller_klass.name)
      end
      it 'has the events set' do
        expect(event_handler.events).to be == ['my_event1', 'my_event2']
      end
    end

  end

end
