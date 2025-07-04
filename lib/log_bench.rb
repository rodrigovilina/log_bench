# frozen_string_literal: true

require "zeitwerk"
require "json"
require "time"
require "curses"
require "lograge"

loader = Zeitwerk::Loader.for_gem
loader.ignore("#{__dir__}/generators")
loader.setup

module LogBench
  class Error < StandardError; end

  extend LogBench::Parse
  extend LogBench::Setup

  singleton_class.attr_accessor :configuration
  self.configuration = Configuration.new
end

# Load Railtie if Rails is available
require "log_bench/railtie" if defined?(Rails)
