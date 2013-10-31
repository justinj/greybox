module Greybox
  describe Runner do
    before do
      FakeFS.activate!

      FileUtils.touch "inputfile.input"
    end

    after do
      FakeFS.activate!
      Dir.glob("*").each { |f| FileUtils.rm f }
      FakeFS.deactivate!
    end

    # it should be noted these are just the defaults
    # for these tests to reduce duplication,
    # the real-world defaults are different
    def defaults
      {
        input: "*.input",
        expected: ->(input) { "output_file" },
        blackbox_command: "echo BLACKBOX_COMMAND",
        comparison: ->(actual, expected) { actual == expected },
      }
    end

    attr_reader :runner

    def with_config(config = {})
      @runner = Runner.new(stub(defaults.merge(config)))
    end

    describe "finding files" do
      it "uses the glob to find files" do
        with_config
        runner.files.must_equal ["inputfile.input"]
      end

      it "uses the 'expected' value to determine the expected name" do
        with_config(expected: ->(input) {
          input.gsub(/\.input$/, ".output")
        })
        runner.expected_filename("hello.input").must_equal "hello.output"
      end

      it "complains if the output is the same as the input" do
        with_config(expected: ->(input){ input })
        ->() { runner.expected_filename("input.input") }.must_raise RuntimeError
      end
    end

    describe "running commands" do
      it "uses the provided test command" do
        with_config(test_command: "echo TEST_COMMAND")
        runner.expects(:`).with("echo TEST_COMMAND")
        runner.expects(:`).with("echo BLACKBOX_COMMAND")
        runner.run
      end

      it "inserts filenames for %'s" do
        with_config(test_command: "echo hi %")
        runner.expects(:`).with "echo hi inputfile.input"
        runner.expects(:`).with "echo BLACKBOX_COMMAND"
        runner.run
      end

      it "uses the provided blackbox command to find the expected value for cases that don't have one yet" do
        with_config(test_command: "echo hi",
                    blackbox_command: "echo output")
        runner.expects(:`).with "echo hi"
        runner.expects(:`).with "echo output"
        runner.run
      end

      it "does not run the command if the file already exists" do
        with_config(test_command: "echo hi",
                    blackbox_command: "echo output")
        FileUtils.touch("output_file")
        runner.expects(:`).with "echo hi"
        runner.run
      end

      it "inserts output filenames for %'s in the blackbox command" do
        with_config(test_command: "echo hi",
                    blackbox_command: "echo output < %")
        runner.expects(:`).with "echo hi"
        runner.expects(:`).with "echo output < inputfile.input"
        runner.run
      end
    end

    describe "asserting output" do
      it "compares for equality by default" do
        with_config(test_command: "echo hi",
                    blackbox_command: "echo hi")
        runner.run
        runner.failures.must_be_empty
      end

      it "has a failure if a test fails" do
        with_config(test_command: "echo hi",
                    blackbox_command: "echo hello")
        runner.run
        runner.failures.wont_be_empty
      end

      it "compares by the provided comparison" do
        with_config(comparison: ->(actual, expected) { actual == "hi\n" },
                    test_command: "echo hi",
                    blackbox_command: "echo hello")
        runner.run
        runner.failures.must_be_empty
      end
    end
  end
end
