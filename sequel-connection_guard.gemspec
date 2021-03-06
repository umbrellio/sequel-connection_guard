# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.required_ruby_version = ">= 2.5.1"

  spec.name          = "sequel-connection_guard"
  spec.version       = "0.1.0"
  spec.authors       = ["Alexander Komarov"]
  spec.email         = %w[ak@akxcv.com oss@umbrellio.biz]

  spec.summary       = "A set of tools for working with unreliable databases."
  spec.description   = "Provides an abstraction for working with unreliable databases safely."
  spec.homepage      = "https://github.com/umbrellio/sequel-connection_guard"
  spec.license       = "MIT"

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.require_paths = %w[lib]

  spec.add_dependency "sequel", "> 5.5"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.8"
  spec.add_development_dependency "armitage-rubocop", "~> 0.33"
  spec.add_development_dependency "rubocop-config-umbrellio", "~> 0.70.0"
  spec.add_development_dependency "pg", "~> 1.0"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "coveralls", "~> 0.8"
  spec.add_development_dependency "simplecov", "~> 0.16"
end
