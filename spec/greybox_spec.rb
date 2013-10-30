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
  end
end
