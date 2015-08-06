require 'spec_helper'
require 'tin_can/event'
require 'byebug'

describe TinCan::Event do
  let(:channel) { "namesapce.my_channel" }
  let(:payload) { {my_model_id: 123} }
  let(:event) { described_class.new(channel, payload) }
  subject { event }

  describe '::default_fallback' do
    it 'sets @@default_fallback_proc' do
      TinCan::Event.default_fallback   do
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

  describe '#fire!' do
    let(:redis) { double("Redis") }
    it "usese redis' publish method" do
      allow( TinCan ).to receive(:redis).and_return(redis)
      allow( redis ).to receive(:publish).with(channel, payload.to_json)
      subject.broadcast!
    end

    it "falls backs back to the default proc if one is set" do
      TinCan::Event.default_fallback do
        "my_proc"
      end
      fallback = TinCan::Event.new("channel", {a: 1}).broadcast!
      expect(fallback).to eq "my_proc"
    end

    it "can define an inline fallback" do
      fallback = TinCan::Event.new("channel", {a: 1}).broadcast! do
        "my_proc"
      end
      expect(fallback).to eq "my_proc"
    end

    it 'uses the inline proc even if a default proc is defined' do
      TinCan::Event.default_fallback do
        "my_proc"
      end
      fallback = TinCan::Event.new("channel", {a: 1}).broadcast! do
        "inline_defined"
      end
      expect(fallback).to eq "inline_defined"
    end
  end
end

