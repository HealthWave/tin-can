require 'spec_helper'

describe TinCan do
  let(:redis_host) { 'localhost' }
  let(:redis_port) { 6379 }
  let(:controller) { "MyController" }
  let(:action) { "MyAction" }
  let(:channel) { "channel" }

  it 'initializes the static variables' do
    expect( TinCan.class_variable_get(:@@redis_host) ).to be_nil
    expect( TinCan.class_variable_get(:@@redis_port) ).to be_nil
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
      subject.subscribe channel, to: controller, action: action
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
      subject.subscribe channel, to: controller, action: action
      subject.start
    end
  end

  describe '::redis' do
    it 'raises an error if either the host or the port are not set' do
      TinCan.class_variable_set(:@@redis_host, nil)
      TinCan.class_variable_set(:@@redis_port, nil)
      expect{ subject.redis }.to raise_error(RuntimeError)
    end

    it 'sets a global variable $redis' do
      subject.config redis_host: redis_host, redis_port: redis_port
      expect(subject.redis).to be_a Redis
    end
  end

end
