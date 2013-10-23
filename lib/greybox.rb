require "set"
require "greybox/version"
require "greybox/configurable"
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

    def config
      @configuration = Configuration.new
      yield configuration
      configuration.verify
    end

    def run
      @failures = []
      input_files.each do |input|
        actual = `#{configuration.test_command.gsub("%", input)}`
        expected = expectation(input)
        check_output(input, actual, expected)
      end
    end

    def expectation(input_filename)
      expected_filename = configuration.expected.call(input_filename)
      unless File.exist?(expected_filename)
        File.open expected_filename, 'w' do |f|
          f.write `#{configuration.blackbox_command.gsub("%", input_filename)}`
        end
      end
      File.read(expected_filename)
    end

    def check
      failures.each { |failure| display_failure(failure) }
      if failures.empty?
        all_passed
      else
        some_failures
      end
    end

    def display_failure((file, values))
      puts "="*10
      puts "FAILURE:"
      puts "For file #{file}:"
      puts Diffy::Diff.new(values[:expected], values[:actual])
    end

    def some_failures
      puts "="*10
      puts "The following tests failed:"
      failures.each do |file, _|
        puts file
      end
      puts "#{input_files.count - failures.count}/#{input_files.count} tests passed"
      exit 1
    end

    def all_passed
      puts "All #{input_files.count} tests passed."
    end

    def check_output(input_file, actual, expected)
      unless configuration.comparison.call(actual, expected)
        @failures << [input_file, { expected: expected, actual: actual }]
      end
    end

    def output_filename(filename)
      result = configuration.expected.call(filename)
      raise "output was same as input for #{filename}" if result == filename
      result
    end

    def input_files
      Dir.glob configuration.input
    end
  end
end
