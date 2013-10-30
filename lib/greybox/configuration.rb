module Greybox
  class Configuration
    include Configurable

    def_property :input, required: true
    def_property :test_command, required: true
    def_property :expected, default: ->(input) { input.gsub(/\.input$/, ".output") }
    def_property :comparison, default: ->(actual, expected) { actual == expected }
    def_property :blackbox_command, required: true

  end
end
