require "greybox/version"
require "minitest"

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
    end

    def run
      @failures = []
      files.each do |input, expected_filename|
        unless File.exist?(expected_filename)
          File.open expected_filename, 'w' do |f|
            f.write `#{@c[:blackbox].gsub("%", input)}`
          end
        end
        actual = `#{@c[:test_command].gsub("%", input)}`
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
      unless @c[:comparison].call(actual, expected)
        @failures << [input_file, { expected: expected, actual: actual }]
      end
    end

    def files
      result = input_files.map { |input| [input, @c[:expected].call(input)] }
      result.each do |input_file, output_file|
        if input_file == output_file
          raise "input file for #{input_file} is the same as the output file"
        end
      end
      result
    end

    def input_files
      Dir.glob @c[:input]
    end
  end

  class Configuration
    attr_accessor :properties
    def initialize
      @properties = {}
    end

    def [](val)
      if properties.has_key? val
        properties[val]
      else
        get_default(val)
      end
    end

    def get_default(property)
      {
        expected: ->(input) { input.gsub(/\.input$/, ".output") },
        comparison: ->(actual, expected) { actual == expected },
      }[property] or raise "Property #{property} was not set in Greybox config"
    end

    MESSAGES = %w(
      input
      expected
      test_command
      blackbox
      comparison
    )

    def method_missing(name, *args)
      if MESSAGES.include? name.to_s 
        properties[name] = args.first
      else
        raise %("#{name}" is not a valid Greybox property.)
      end
    end
  end
end
