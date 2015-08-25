require 'spec_helper'

describe "errors" do
  let(:controller) { "THE CONTROLLER" }
  let(:action) { "THE ACTION" }
  subject { described_class }

  describe TinCan::NotConfigured do
    it 'has the correct error message' do
      message = subject.new.message
      expect( message ).to eq "No routes specified, use ::route to add routes."
    end
  end

  describe TinCan::AlreadyRunning do
    it 'has the correct error message' do
      message = subject.new(111).message
      expect( message ).to eq "A TinCan handler is already running with PID: 111."
    end
  end

  describe TinCan::EventController::ActionMissing do
    it 'has the correct error message' do
      message = subject.new(controller).message
      expect( message ).to eq "Action not supplied for controller: #{controller}."
    end
  end

  describe TinCan::EventController::ActionNotDefined do
    it 'has the correct error message' do
      message = subject.new(action, controller).message
      expect( message ).to eq "The action: #{action} is not defined for #{controller}."
    end
  end

  describe TinCan::EventController::ControllerNotDefined do
    it 'has the correct error message' do
      message = subject.new(controller).message
      expect( message ).to eq "Action #{controller} is not defined."
    end
  end

  describe TinCan::Event::NotReceivedError do
    it 'has the correct error message' do
      message = subject.new("my_super_cool_channel", {a: 1}).message
      expect( message ).to eq  "There were no listeners on the [my_super_cool_channel] channel. The following payload could not be delivered\n\n#{{a: 1}}"
    end
  end

end
