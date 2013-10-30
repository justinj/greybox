module Greybox
  class Runner
    attr_reader :failures
    attr_reader :config

    def initialize(config)
      @config = config
      @failures = []
    end
    def files
      Dir.glob(config.input)
    end

    def expected_filename(input_filename)
      expected_filename = config.expected.call(input_filename)
      raise "Output filename for #{input_filename} was same as input!" if expected_filename == input_filename
      expected_filename
    end

    def expected_for(filename)
      file = expected_filename(filename)
      File.open(file, 'w') do |f|
        f.write run_command(config.blackbox_command, filename)
      end
      File.read(file)
    end

    def run
      files.each do |input_file|
        expected = expected_for(input_file)
        actual = run_command(config.test_command, input_file)
        report_failure(input_file, expected, actual) unless config.comparison.call(actual, expected)
      end
    end

    def run_command(command, file)
      `#{insert_filename(command, file)}`
    end

    def insert_filename(command, filename)
      command.gsub("%", filename)
    end

    def report_failure(filename, expected, actual)
      @failures << { filename: filename, expected: expected, actual: actual }
    end
  end
end
