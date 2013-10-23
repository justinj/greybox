module Greybox
  module Configurable
    attr_accessor :properties

    module ClassMethods
      attr_accessor :defaults
      attr_accessor :required_properties
      def def_property(name, args = {})
        setter = "#{name}=".to_sym
        getter = name
        @defaults ||= {}
        @defaults[name] = args[:default] if args.has_key? :default
        @required_properties ||= Set.new
        @required_properties << name if args[:required]
        define_method(setter) do |value|
          @properties ||= {}
          @properties[name] = value
        end

        define_method(getter) { get_prop(name) }
      end

      def method_missing(name, *args)
        raise "Property #{name} was not defined"
      end
    end

    def get_prop(prop)
       (@properties || {}).fetch(prop, self.class.defaults[prop]) 
    end

    def verify
      self.class.required_properties.each do |prop|
        raise "Property #{prop} is required." unless get_prop(prop)
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end
  end
end
