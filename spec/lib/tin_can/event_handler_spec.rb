require 'spec_helper'
require 'byebug'

describe TinCan::EventHandler do
  let(:events) { %w{channel1 channel2 channel3} }
  let(:event_handler) { described_class.new(events) }
  let(:thread) { double("Thread") }

  subject { event_handler }

  describe '#initialize' do
    it 'sets the events to which the handler will listen to' do
      expect( subject.events ).to eq events
    end
  end

  describe "#handle" do
  end

  describe "#restart" do
    it 'restarts the handler' do
      expect( subject ).to receive(:stop)
      expect( subject ).to receive(:start)
      subject.restart
    end
  end

  describe "#stop" do
    before do
      allow( thread ).to receive(:kill)
    end

    it 'kills the current thread' do
      allow( subject ).to receive(:thread) { thread }
      expect( subject.thread ).to receive(:kill)
      subject.stop
    end

    it 'removes the current thread' do
      subject.instance_variable_set(:@thread, thread)
      subject.stop
      expect( subject.thread ).to be_nil
    end
  end

  describe "#start" do
    it 'stops the current running thread if it exists' do
      expect( subject ).to receive(:stop)
      allow( subject ).to receive(:run!)
      subject.start
    end

    it 'calls run and does not create a new thread of foreground is false' do
      allow( subject ).to receive(:stop)
      expect( subject ).to receive(:run!)
      subject.start foreground: true
      expect( subject.thread ).to be_nil
    end

    it 'runs as a demon' do
      allow( subject ).to receive(:stop)
      expect( Thread ).to receive(:new) { thread }
      subject.start
      expect( subject.thread ).to_not be_nil
    end
  end

  describe "#run!" do
    xit "runs the daemon"
  end

end
