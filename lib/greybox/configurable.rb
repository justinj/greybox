module Greybox
  module Configurable
    attr_accessor :properties

    module ClassMethods
      attr_accessor :required_properties
      def def_property(name, args = {})
        setter = "#{name}=".to_sym
        getter = name
        (@defaults ||= {})[name] = args[:default] if args.has_key? :default
        (@required_properties ||= Set.new) << name if args[:required]

        # Stolen from RubyTapas episodes 27 and 28
        mod = if const_defined?(:Properties, false)
                const_get(:Properties)
              else
                const_set(:Properties, new_blank_properties_module)
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

      def defaults
        @defaults || {}
      end

      private
      def new_blank_properties_module
        Module.new do
          class << self
            def to_s
              "Properties(#{properties.join(", ")})"
            end
            alias_method :inspect, :to_s

            def properties
              instance_methods(false).reject { |m| m.to_s.end_with? "=" }
            end
          end
        end
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
