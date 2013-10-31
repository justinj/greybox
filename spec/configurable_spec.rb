module Greybox
  describe Configurable do

    def config
      @config ||= configuration_class.new
    end

    describe "the inserted module" do
      it "shows what properties have been defined" do
        cls = Class.new do
          include Configurable

          def_property :some_property
          def_property :some_other_property
        end
        cls.ancestors.map(&:to_s).must_include "Properties(some_property, some_other_property)"
      end
    end

    describe "setting a property" do
      def configuration_class
        Class.new do
          include Configurable

          def_property :regular
        end
      end

      it "lets you set valid properties" do
        config.regular = "abc"
        config.regular.must_equal "abc"
      end

      it "does not let you set invalid properties" do
        -> do
          config.unset = "abc"
        end.must_raise NoMethodError
      end
    end

    describe "required properties" do
      def configuration_class
        Class.new do
          include Configurable

          def_property :req, required: true
        end
      end

      it "does not complain if the required property is set" do
        config.req = "abc"
        config.verify
      end

      it "complains if you do not set a property" do
        -> do
          config.verify
        end.must_raise RuntimeError
      end
    end

    describe "default values" do
      def configuration_class
        Class.new do
          include Configurable

          def_property :with_default, default: 5
        end
      end

      it "uses the default value" do
        config.with_default.must_equal 5
      end

      it "lets you override the default" do
        config.with_default = 6
        config.with_default.must_equal 6
      end
    end
  end
end
