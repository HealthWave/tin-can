require "codeclimate-test-reporter"
CodeClimate::TestReporter.start
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'tin_can'
require 'support/tin_can_support'
