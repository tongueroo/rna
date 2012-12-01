# -*- encoding: utf-8 -*-
require File.expand_path('../lib/rna/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Tung Nguyen"]
  gem.email         = ["tongueroo@gmail.com"]
  gem.description   = %q{Rna DSL generates chef solo node.json files.}
  gem.summary       = %q{Rna DSL generates chef solo node.json files.}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "rna"
  gem.require_paths = ["lib"]
  gem.version       = Rna::VERSION

  gem.add_dependency "json"
  gem.add_dependency "thor"
  gem.add_dependency "aws-sdk"

  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'guard'
  gem.add_development_dependency 'guard-rspec'
  gem.add_development_dependency 'guard-bundler'
  gem.add_development_dependency 'rb-fsevent'

end