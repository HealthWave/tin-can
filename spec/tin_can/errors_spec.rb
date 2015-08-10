require 'spec_helper'

describe "errors" do
  let(:controller) { "THE CONTROLLER" }
  let(:action) { "THE ACTION" }
  subject { described_class }

  describe TinCan::NotConfigured do
    it 'has the correct error message' do
      message = subject.new.message
      expect( message ).to eq "No routes specified, use ::subscribe to add routes."
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

end
