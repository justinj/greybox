module Greybox
  describe Greybox do
    describe "errors" do
      it "complains if a missing property is gone before being run" do
        -> do
          Greybox.config do |c|
          end
        end.must_raise RuntimeError
      end
    end

    describe "running the tests" do
      it "defers to runner to actually run the tests" do
        Runner.any_instance.expects(:run)
        Greybox.setup do |c|
          c.input = "test/*.input"
          c.test_command = "echo hi"
        end
      end
    end

    describe "printing the failures" do
      it "prints out each failure" do
        Diffy::Diff.stubs(:new).returns("-a\n+b\n")
        $stdout.expects(:puts).with("FAILED:")
        $stdout.expects(:puts).with("filename: a.input")
        $stdout.expects(:puts).with("-a\n+b\n")
        Runner.any_instance.stubs(:failures).returns([{filename: "a.input",
                                                       expected: "a",
                                                       actual: "b"}])
        Greybox.setup do |c|
          c.input = "test/*.input"
          c.test_command = "echo hi"
        end
      end
    end
  end
end
