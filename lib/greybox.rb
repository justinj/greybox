require "set"
require "greybox/version"
require "greybox/configurable"
require "greybox/runner"
require "greybox/configuration"

module Greybox
  class << self
    attr_reader :failures
    attr_reader :configuration
    def setup(&blk)
      config(&blk)
      run
      check
    end

    def run
      runner = Runner.new(configuration)
      runner.run
    end

    def config
      @configuration = Configuration.new
      yield configuration
      configuration.verify
    end

    def separator
      "=========="
    end

    def display_failure((file, values))
      puts separator
      puts "FAILURE:"
      puts "For file #{file}:"
      puts Diffy::Diff.new(values[:expected], values[:actual])
    end
  end
end
