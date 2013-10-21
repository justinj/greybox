module Greybox
  describe Greybox do
    before do
      FakeFS.activate!

      FileUtils.touch "file1.input"
      FileUtils.touch "file2.input"
      FileUtils.touch "file3.input"
    end

    after do
      FakeFS.activate!
      Dir.glob("*").each { |f| FileUtils.rm f }
      FakeFS.deactivate!
    end

    describe "finding files" do
      it "uses the glob given for test files" do
        Greybox.config do |c|
          c.input "*.input"
        end
        Greybox.input_files.must_equal %w(file1.input file2.input file3.input)
      end

      it "uses the provided function to figure out the expected name" do
        Greybox.config do |c|
          c.input "*.input"
          c.expected ->(input) { input.gsub(/\.input$/, ".outputfile") }
        end

        Greybox.files.must_equal [
          ["file1.input", "file1.outputfile"],
          ["file2.input", "file2.outputfile"],
          ["file3.input", "file3.outputfile"],
        ]
      end

      it "just replaces any occurrence of input with output if no procedure is given" do
        Greybox.config do |c|
          c.input "*.input"
        end

        Greybox.files.must_equal [
          ["file1.input", "file1.output"],
          ["file2.input", "file2.output"],
          ["file3.input", "file3.output"],
        ]
      end
    end

    describe "running commands" do
      it "uses the provided test command" do
        FileUtils.touch "file1.output"
        FileUtils.touch "file2.output"
        FileUtils.touch "file3.output"

        Greybox.config do |c|
          c.input "*.input"
          c.test_command "run %"
          c.blackbox "cat < %"
        end

        Greybox.expects(:`).with("run file1.input")
        Greybox.expects(:`).with("run file2.input")
        Greybox.expects(:`).with("run file3.input")

        Greybox.run
      end

      it "uses the provided blackbox command to find the expected value for cases that don't have one yet" do
        FileUtils.rm "file2.input"
        FileUtils.rm "file3.input"
        Greybox.expects(:`).with("cat < file1.input")
        Greybox.expects(:`).with("echo Hello")

        Greybox.config do |c|
          c.input "*.input"
          c.test_command "echo Hello"
          c.blackbox "cat < %"
        end

        Greybox.run
      end
    end

    describe "asserting output" do
      it "has no complaints if the output is the same as the expected" do
        File.open("file1.input", 'w') { |f| f.write "input" }
        File.open("file1.output", 'w') { |f| f.write "output\n" }
        FileUtils.rm "file2.input"
        FileUtils.rm "file3.input"

        Greybox.config do |c|
          c.input "*.input"
          c.test_command "echo output"
        end

        Greybox.run
        Greybox.failures.must_be :empty?
      end

      it "complains if the output is different" do
        File.open("file1.input", 'w') { |f| f.write "input" }
        File.open("file1.output", 'w') { |f| f.write "foo\n" }
        FileUtils.rm "file2.input"
        FileUtils.rm "file3.input"

        Greybox.config do |c|
          c.input "*.input"
          c.test_command "echo bar"
        end

        Greybox.run
        FakeFS.deactivate!
        Greybox.failures.must_equal [
          ["file1.input", { expected: "foo\n", actual: "bar\n" }]
        ]
        FakeFS.activate!
      end
    end
  end
end
