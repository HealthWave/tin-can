class TinCan::AlreadyRunning < StandardError
  def initialize(pid)
    super("A TinCan handler is already running with PID: #{pid}.")
  end
end


class TinCan::NotConfigured < StandardError
  def initialize
    super("No routes specified, use ::route to add routes.")
  end
end

class TinCan::EventController::ActionMissing < StandardError
  def initialize controller
    super "Action not supplied for controller: #{controller}."
  end
end

class TinCan::EventController::ActionNotDefined < StandardError
  def initialize action, controller
    super "The action: #{action} is not defined for #{controller}."
  end
end

class TinCan::EventController::ControllerNotDefined < StandardError
  def initialize controller
    super "Action #{controller} is not defined."
  end
end
