module Greybox
  describe Greybox do
    before do
      Dir.stubs(:glob).returns %w(
        file1.input
        file2.input
        file3.input
      )
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
        File.stubs(:exist?).returns(true) # so we don't try to create the expected
        Greybox.config do |c|
          c.input "*.input"
          c.test_command "run %"
          c.blackbox "cat < %"
        end

        Greybox.expects(:system).with("run file1.input")
        Greybox.expects(:system).with("run file2.input")
        Greybox.expects(:system).with("run file3.input")

        Greybox.run
      end

      it "uses the provided blackbox command to find the expected value for cases that don't have one yet" do
        Dir.stubs(:glob).returns %w(file1.input)
        File.stubs(:exist?).returns(false)
        Greybox.expects(:system).with("cat < file1.input > file1.output")
        Greybox.expects(:system).with("echo Hello")

        Greybox.config do |c|
          c.input "*.input"
          c.test_command "echo Hello"
          c.blackbox "cat < %"
        end

        Greybox.run
      end
    end
  end
end
