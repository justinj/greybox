module Greybox
  module Configurable
    attr_accessor :properties

    module ClassMethods
      attr_accessor :defaults
      def def_property(name, args = {})
        setter = "#{name}=".to_sym
        getter = name
        @defaults ||= {}
        @defaults[name] = args[:default] if args.has_key? :default
        define_method(setter) do |value|
          @properties ||= {}
          @properties[name] = value
        end

        define_method(getter) { @properties.fetch(name, self.class.defaults[name]) }
      end

      def method_missing(name, *args)
        raise "Property #{name} was not defined"
      end
    end


    def self.included(base)
      base.extend(ClassMethods)
    end
  end
end
