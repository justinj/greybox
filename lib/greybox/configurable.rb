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

        # Stolen from RubyTapas episodes 27 and 28
        mod = if const_defined?(:Properties, false)
                const_get(:Properties)
              else
                new_mod = Module.new do
                  def self.to_s
                    "Properties(#{properties.join(", ")})"
                  end

                  def self.properties
                    instance_methods(false).reject { |m| m.to_s.end_with? "=" }
                  end

                  def self.inspect
                    self.to_s
                  end
                end
                const_set(:Properties, new_mod)
              end

        mod.module_eval %Q{
          def #{setter}(value)
            @properties ||= {}
            @properties[:#{name}] = value
          end

          def #{getter}
            get_prop(:#{name})
          end
        }

        include mod
      end

      def method_missing(name, *args)
        raise "Property #{name} was not defined"
      end
    end

    def get_prop(prop)
       (@properties || {}).fetch(prop, self.class.defaults[prop]) 
    end

    def verify
      p self.class.ancestors
      self.class.required_properties.each do |prop|
        raise "Property #{prop} is required." unless get_prop(prop)
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end
  end
end
