require "set"
require "diffy"
require "greybox/version"
require "greybox/configurable"
require "greybox/runner"
require "greybox/configuration"

module Greybox
  class << self
    attr_reader :failures
    attr_reader :configuration
    attr_reader :runner
    def setup(&blk)
      config(&blk)
      run
      check
    end

    def run
      @runner = Runner.new(configuration)
      runner.run
    end

    def check
      runner.failures.each do |failure|
        puts "FAILED:"
        puts "filename: #{failure[:filename]}"
        puts Diffy::Diff.new(failure[:expected], failure[:actual])
      end
    end

    def config
      @configuration = Configuration.new
      yield configuration
      configuration.verify
    end
  end
end
