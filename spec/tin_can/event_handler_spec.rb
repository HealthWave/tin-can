require 'spec_helper'
require 'byebug'
describe TinCan::EventHandler do
  let(:events) { ['my_event1', 'my_event2'] }
  let(:event_handler) { described_class.new(events) }


  subject {event_handler}

  describe '#initialize' do
    it 'sets the events to which the handler will listen to' do
      expect( event_handler.events ).to eq events
    end
  end

  describe "#start!" do
    context 'code' do
      it 'raises error if action not defined' do

        controller_klass, action = TinCan.routes['my_event3']
        # TODO
        expect{event_handler.process_message({message: 'ok'}.to_json, 'my_event3')}.to raise_error#(TinCan::EventController::ActionNotDefined.new action, controller_klass.name)

      end

      it 'Fails with an error if already running' do
        allow(File).to receive(:read).and_return(111)
        allow(Process).to receive(:getpgid).and_return(true)
        allow(TinCan.redis).to receive(:subscribe).and_return(true)
        # TODO
        expect{ subject.start(foreground: true, test_mode: true) }.to raise_error #TinCan::AlreadyRunning.new(111)
      end

      it 'Creates a pid file if the file doesnt exist but the process is running' do
        pidfile = File.expand_path('./tin-can.pid')
        allow(subject).to receive(:subscribe_to_events).and_return(true)
        allow(File).to receive(:exists?).and_return(false)
        allow(TinCan).to receive(:`).and_return(111)
        expect(File).to receive(:open).with(pidfile, 'w')
        subject.start(foreground: true, test_mode: true)
      end

      describe 'when running in background' do
        it 'runs the required methods' do
          pidfile = File.expand_path('./tin-can.pid')
          log_file_path = File.expand_path('./tin-can.log')
          allow(File).to receive(:exists?).and_return(false)
          allow(TinCan).to receive(:`).and_return(111)
          allow(Process).to receive(:pid).and_return(111)
          allow(subject).to receive(:subscribe_to_events).and_return(true)
          expect(subject).to receive(:set_log_file).and_return(log_file_path)
          expect(subject).to receive(:daemonize).with(pidfile, log_file_path, test_mode: true)
          expect(subject).to receive(:set_logger).with(log_file_path)
          expect(subject).to receive(:send_output_to_log_file).with(log_file_path)
          expect(subject).to receive(:write_pidfile).with(pidfile, 111)
          expect(subject).to receive(:subscribe_to_events)
          subject.start(test_mode: true)
        end
      end
    end
  end
  describe "::subscribe_to_events" do
    it 'has the events set and subscribe to it' do
      allow(TinCan.redis).to receive(:subscribe).and_return(true)
      expect(event_handler.events).to be == ['my_event1', 'my_event2']
      expect(TinCan.redis).to receive(:subscribe).with('my_event1', 'my_event2')

      subject.subscribe_to_events
    end
  end

  describe '::set_pid_file' do
    it 'returns the pid file path inside tmp or in same folder' do
      expect(subject.set_pid_file).to be == File.expand_path('./tin-can.pid')
      allow(File).to receive(:exists?).and_return(true)
      expect(subject.set_pid_file).to be == File.expand_path('./tmp/pids/tin-can.pid')
    end
  end

  describe '::set_log_file' do
    it 'returns the log file path inside log or in same folder' do
      expect(subject.set_log_file).to be == File.expand_path('./tin-can.log')
      allow(File).to receive(:exists?).and_return(true)
      expect(subject.set_log_file).to be == File.expand_path('./log/tin-can.log')
    end
  end

  describe '::daemonize' do
    it 'prints a message and sends the process to background' do
      pidfile = File.expand_path('./tin-can.pid')
      log_file_path = File.expand_path('./tin-can.log')
      allow(Process).to receive(:pid).and_return(1)
      expect(STDOUT).to receive(:puts).with "Starting TinCan daemon:\n- PID 1\n- PID file #{pidfile}\n- Log File #{log_file_path}"

      subject.daemonize(pidfile, log_file_path, test_mode: true)
    end
  end

  describe '::send_output_to_log_file' do
    it 'redirect the the output to a file' do
      skip "This is sending the test to the background, better not test it."
      log_file_path = File.expand_path('./tin-can.log')

      subject.send_output_to_log_file(log_file_path)
      expect(TinCan.logger.instance_variable_get(:@logdev).dev.tty?).to be false
      # put the logger back
      TinCan.logger = nil
    end
  end

  describe '::write_pidfile' do
    it 'Writes the pidfile' do
      expect(File).to receive(:open).with('file', 'w')
      subject.write_pidfile('file', 111)
    end
  end

  describe '::process_message' do
    it 'routes the event to the correct controller and action' do
      controller_klass, action = TinCan.routes['my_event1']
      # some_action1 is defined on tin_can_support.rb
      expect_any_instance_of(controller_klass).to receive(:some_action1)
      subject.process_message '{"message": "ok"}', 'my_event1'
    end

  end

  describe '::stop' do
    it 'calls the methods and stops TinCan' do
      pidfile = 'file'
      allow(subject).to receive(:already_running?).and_return(true)
      allow(subject).to receive(:read_pidfile).with(pidfile).and_return(111)
      allow(Process).to receive(:kill).with('QUIT', 111).and_return(true)

      expect(STDOUT).to receive(:puts).with "Stopping TinCan with PID: 111..."
      expect(STDOUT).to receive(:puts).with "Removing PID file #{pidfile}..."
      expect(STDOUT).to receive(:puts).with "TinCan stopped."
      expect(subject).to receive(:read_pidfile)
      expect(File).to receive(:delete).with(pidfile)

      subject.stop(pidfile: pidfile)
    end
    it 'detects tin-can was not running and deletes the stale pid file' do
      pidfile = 'file'
      allow(subject).to receive(:already_running?).and_return(false)
      allow(subject).to receive(:read_pidfile).with(pidfile).and_return(111)
      allow(File).to receive(:exists?).and_return(true)


      expect(STDOUT).to receive(:puts).with "Could not find any instances of TinCan running."
      # deletes pid file if exists
      expect(File).to receive(:delete).with(pidfile)
      expect(STDOUT).to receive(:puts).with "Removing stale PID file #{pidfile}..."
      subject.stop(pidfile: pidfile)

    end

  end

  describe '::status' do
    it 'if its already running' do
      pid = 111
      allow(subject).to receive(:read_pidfile).and_return(pid)
      allow(subject).to receive(:already_running?).and_return(true)
      expect(STDOUT).to receive(:puts).with "TinCan is running with pid #{pid}."
      subject.status
    end
    it 'if its not running' do
      pid = 111
      allow(subject).to receive(:read_pidfile).and_return(pid)
      allow(subject).to receive(:already_running?).and_return(false)
      expect(STDOUT).to receive(:puts).with "TinCan is NOT running."
      subject.status
    end
  end

  describe '::already_running?' do
    it 'returns true if process is running' do
      allow(Process).to receive(:getpgid).with(111).and_return(true)
      expect(subject.already_running?(111)).to be true
    end
    it 'returns false if process is not running' do
      allow(Process).to receive(:getpgid).with(111).and_return(false)
      expect(subject.already_running?(111)).to be false
    end
  end

end
