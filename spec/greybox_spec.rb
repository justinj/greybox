module Greybox
  describe Greybox do
    before do
      FakeFS.activate!

      FileUtils.touch "file1.input"
      FileUtils.touch "file2.input"
      FileUtils.touch "input.input"
    end

    after do
      FakeFS.activate!
      Dir.glob("*").each { |f| FileUtils.rm f }
      FakeFS.deactivate!
    end

    describe "finding files" do
      it "uses the glob given for test files" do
        Greybox.config do |c|
          c.input = "*.input"
          c.test_command = ""
        end
        Greybox.input_files.must_equal %w(file1.input file2.input input.input)
      end

      it "uses the provided function to figure out the expected name" do
        Greybox.config do |c|
          c.test_command = ""
          c.input = "*.input"
          c.expected = ->(input) { input.gsub(/\.input$/, ".outputfile") }
        end

        Greybox.files.must_equal [
          ["file1.input", "file1.outputfile"],
          ["file2.input", "file2.outputfile"],
          ["input.input", "input.outputfile"],
        ]
      end

      it "complains if the output for a file is the same as the input" do
        Greybox.config do |c|
          c.test_command = ""
          c.input = "*.input"
          c.expected = ->(input) { input }
        end

        ->() { Greybox.files }.must_raise RuntimeError
      end

      it "changes .input to .output if no procedure is given" do
        Greybox.config do |c|
          c.test_command = ""
          c.input = "*.input"
        end

        Greybox.files.must_equal [
          ["file1.input", "file1.output"],
          ["file2.input", "file2.output"],
          ["input.input", "input.output"],
        ]
      end
    end

    describe "running commands" do
      it "uses the provided test command" do
        FileUtils.touch "file1.output"
        FileUtils.touch "file2.output"
        FileUtils.touch "input.output"

        Greybox.config do |c|
          c.input = "*.input"
          c.test_command = "run %"
          c.blackbox_command = "cat < %"
        end

        Greybox.expects(:`).with("run file1.input")
        Greybox.expects(:`).with("run file2.input")
        Greybox.expects(:`).with("run input.input")

        Greybox.run
      end

      it "uses the provided blackbox command to find the expected value for cases that don't have one yet" do
        FileUtils.rm "file2.input"
        FileUtils.rm "input.input"
        Greybox.expects(:`).with("cat < file1.input")
        Greybox.expects(:`).with("echo Hello")

        Greybox.config do |c|
          c.input = "*.input"
          c.test_command = "echo Hello"
          c.blackbox_command = "cat < %"
        end

        Greybox.run
      end
    end

    describe "asserting output" do
      before do
        File.open("file1.input", 'w') { |f| f.write "input" }
        File.open("file1.output", 'w') { |f| f.write "foo\n" }
        FileUtils.rm "file2.input"
        FileUtils.rm "input.input"
      end
      it "has no complaints if the output is the same as the expected" do
        Greybox.config do |c|
          c.input = "*.input"
          c.test_command = "echo foo"
        end

        Greybox.run
        Greybox.failures.must_be_empty
      end

      it "complains if the output is different" do
        Greybox.config do |c|
          c.input = "*.input"
          c.test_command = "echo bar"
        end

        Greybox.run
        FakeFS.deactivate! # minitest uses the file system for diffs
        Greybox.failures.must_equal [
          ["file1.input", { expected: "foo\n", actual: "bar\n" }]
        ]
        FakeFS.activate!
      end

      it "uses the custom comparer if one is provided" do
        Greybox.config do |c|
          c.input = "*.input"
          c.test_command = "echo f"
          c.comparison = ->(actual, expected) { expected.include? actual[0] }
        end

        Greybox.run
        Greybox.failures.must_be_empty
      end
    end

    describe "errors" do
      it "complains if a missing property is gone before being run" do
        -> do
          Greybox.config do |c|
          end
        end.must_raise RuntimeError
      end
    end
  end
end
