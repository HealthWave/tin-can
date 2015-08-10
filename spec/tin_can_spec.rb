require 'spec_helper'

describe TinCan do
  let(:redis_host) { 'myredishost' }
  let(:redis_port) { 9999 }
  let(:controller) { MyEventController }
  let(:action) { "some_action1" }
  let(:channel) { "my_event1" }

  it 'initializes the static variables' do
    expect( TinCan.class_variable_get(:@@redis_host) ).to be == 'localhost'
    expect( TinCan.class_variable_get(:@@redis_port) ).to be == 6379
    expect( TinCan.class_variable_get(:@@handler) ).to be_nil
    expect( TinCan.class_variable_get(:@@routes) ).to_not be_nil
  end

  describe '::logger' do
    it 'sets a logger if running under rails' do

    end
  end
  describe '::config' do
    it 'sets both instance varaibles' do
      subject.config redis_host: redis_host, redis_port: redis_port
      expect( TinCan.class_variable_get(:@@redis_host) ).to eq redis_host
      expect( TinCan.class_variable_get(:@@redis_port) ).to eq redis_port
    end
  end

  describe '::subscribe' do
    it 'adds the routers info to the @@routes hash' do
      subject.routes do
        route 'my_event1', to: MyEventController, action: 'some_action1'
      end
      expect( subject.routes ).to include channel
      expect( subject.routes[channel] ).to include controller, action
    end
  end


  describe '::start' do
    it 'raises TinCan::NotConfigured if the routes were not set' do
      allow_any_instance_of(TinCan::EventHandler).to receive(:start)
      allow( subject ).to receive(:routes) { nil }
      expect{ subject.start }.to raise_error TinCan::NotConfigured
    end

    it 'starts the handler' do
      expect_any_instance_of(TinCan::EventHandler).to receive(:start)
      subject.routes do
        route 'my_event1', to: MyEventController, action: 'some_action1'
      end
      subject.start
    end
  end

  describe '::redis' do
    it 'sets a global variable $redis' do
      subject.config redis_host: redis_host, redis_port: redis_port
      expect(subject.redis).to be_a Redis
    end
  end

end
