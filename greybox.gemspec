# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'greybox/version'

Gem::Specification.new do |spec|
  spec.name          = "greybox"
  spec.version       = Greybox::VERSION
  spec.authors       = ["Justin Jaffray"]
  spec.email         = ["justin.jaffray@gmail.com"]
  spec.description   = %q{Test against a black box.}
  spec.summary       = %q{Easily test school assignments or other projects where you have a reference}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "diffy"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "fakefs"
  spec.add_development_dependency "mocha"
  spec.add_development_dependency "simplecov"
end
