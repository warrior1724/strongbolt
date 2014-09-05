# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'strongbolt/version'

Gem::Specification.new do |spec|
  spec.name          = "strongbolt"
  spec.version       = StrongBolt::VERSION
  spec.authors       = ["Thomas Césaré-Herriau"]
  spec.email         = ["thomas.cesareherriau@gmail.com"]
  spec.summary       = "RBAC Framework for model-level authorization"
  spec.description   = "Use model-level authorization with a very granular roles and permissions definition."
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'awesome_nested_set'

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.1"
  spec.add_development_dependency 'sqlite3', '1.3.9'
  spec.add_development_dependency 'shoulda-matchers'
end
