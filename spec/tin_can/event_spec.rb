require 'spec_helper'
require 'tin_can/event'
require 'byebug'

describe TinCan::Event do
  let(:channel) { "namesapce.my_channel" }
  let(:payload) { {my_model_id: 123} }
  let(:event) { described_class.new(channel, payload) }
  subject { event }

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
      subject.fire!
    end
  end
end

