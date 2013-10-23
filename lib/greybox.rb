require "minitest"
require "set"
require "greybox/version"
require "greybox/configurable"
require "greybox/configuration"

module Greybox
  class << self
    include Minitest::Assertions

    attr_reader :failures
    def setup(&blk)
      config(&blk)
      run
      check
    end

    def config
      @c = Configuration.new
      yield @c
      @c.verify
    end

    def run
      @failures = []
      files.each do |input, expected_filename|
        unless File.exist?(expected_filename)
          File.open expected_filename, 'w' do |f|
            f.write `#{@c.blackbox.gsub("%", input)}`
          end
        end
        actual = `#{@c.test_command.gsub("%", input)}`
        expected = File.read(expected_filename)
        check_output(input, actual, expected)
      end
    end

    def check
      failures.each do |file, values|
        puts "FAILURE:"
        puts "For file #{file}:"
        puts diff(values[:expected], values[:actual])
      end
      if failures.empty?
        puts "All tests passed."
      else
        puts "="*10
        exit 1
      end
    end

    def check_output(input_file, actual, expected)
      unless @c.comparison.call(actual, expected)
        @failures << [input_file, { expected: expected, actual: actual }]
      end
    end

    def files
      result = input_files.map { |input| [input, @c.expected.call(input)] }
      result.each do |input_file, output_file|
        if input_file == output_file
          raise "input file for #{input_file} is the same as the output file"
        end
      end
      result
    end

    def input_files
      Dir.glob @c.input
    end
  end
end
