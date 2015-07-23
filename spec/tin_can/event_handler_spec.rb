require 'spec_helper'
require 'byebug'

describe TinCan::EventHandler do
  let(:events) { %w{channel1 channel2 channel3} }
  let(:event_handler) { described_class.new(events) }
  let(:thread) { double("Thread") }
  let(:redis) { double("Redis") }

  subject { event_handler }

  describe '#initialize' do
    it 'sets the events to which the handler will listen to' do
      expect( subject.events ).to eq events
    end
  end

  describe "#restart" do
    it 'restarts the handler' do
      expect( subject ).to receive(:stop)
      expect( subject ).to receive(:start)
      subject.restart
    end
  end

  describe "#stop" do
    it 'kills the current thread' do
      expect( subject ).to receive(:system).exactly(3).times
      subject.stop
    end

    it 'removes the current thread' do
      allow( subject ).to receive(:system)
      subject.stop
      expect( subject.pid ).to be_nil
    end
  end

  describe "#start!" do
    before { allow(Daemons).to receive(:daemonize) }
    context 'system' do
      xit 'kills the existing process'
      xit 'creates a file that stores a reference to the pid'
    end

    context 'code' do
      before do
        allow_any_instance_of( TinCan::EventHandler ).to receive(:system)
      end

      it 'subscribes redis to the channels' do
        allow( TinCan ).to receive(:redis) { redis }
        expect( redis ).to receive(:subscribe).with(*events)
        subject.start
      end
    end

  end

end
