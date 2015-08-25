require 'spec_helper'
require 'tin_can/event'
require 'byebug'

describe TinCan::Event do
  let(:channel) { "my_channel" }
  let(:payload) { {my_model_id: 123} }
  let(:event) { described_class.new(channel, payload) }
  subject { event }

  describe '::default_fallback' do
    it 'sets @@default_fallback_proc' do
      TinCan::Event.default_fallback do
        "my_proc"
      end
      expect( TinCan::Event.class_variable_get(:@@default_error_fallback_proc) ).to_not be_nil
    end
  end

  describe '#initialize' do
    it 'sets the channel' do
      expect(subject.channel).to eq channel
    end

   it 'sets the payload' do
      expect(subject.payload).to be_a String
      expect(subject.payload).to match Regexp.new(payload[:my_model_id].to_s)
    end
  end

  describe '#broadcast!' do
    let(:redis) { double("Redis") }
    let(:default_error_fallback_proc) { TinCan::Event.default_fallback }

    before do
      allow( TinCan.redis ).to receive(:publish).with(channel, payload.to_json).and_return(0)
    end

    it 'returns true if the message was received' do
      allow( TinCan.redis ).to receive(:publish).with(channel, payload.to_json).and_return(1)
      expect( event.broadcast! ).to eq true
    end

    it 'returns false if the message was not received' do
      expect( event.broadcast! ).to eq false
    end

    it "usese redis' publish method" do
      allow( TinCan ).to receive(:redis).and_return(redis)
      expect( TinCan.redis ).to receive(:publish).with(channel, payload.to_json)
      event.broadcast!
    end

    it "falls backs back to the default proc if one is set" do
      TinCan::Event.default_fallback do |e|
        'wooo'
      end

      expect(default_error_fallback_proc).to receive(:call)
      event.broadcast!
    end

    it "can define an inline fallback" do
      expect{ |b| event.broadcast!(&b) }.to yield_control
    end

    it 'uses the inline proc even if a default proc is defined' do
      TinCan::Event.default_fallback do
        "my_proc"
      end
      expect(default_error_fallback_proc).to_not receive(:call)
      event.broadcast!{}
    end
  end
end

