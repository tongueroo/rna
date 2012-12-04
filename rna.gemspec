# -*- encoding: utf-8 -*-
require File.expand_path('../lib/rna/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Tung Nguyen"]
  gem.email         = ["tongueroo@gmail.com"]
  gem.description   = %q{Rna is a ruby gem that provides simple DSL for generating node.json files required by chef-solo.
.}
  gem.summary       = %q{Rna is a ruby gem that provides simple DSL for generating node.json files required by chef-solo.
.}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "rna"
  gem.require_paths = ["lib"]
  gem.version       = Rna::VERSION

  gem.add_dependency "rake"
  gem.add_dependency "json"
  gem.add_dependency "thor"
  gem.add_dependency "aws-sdk"

  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'guard'
  gem.add_development_dependency 'guard-rspec'
  gem.add_development_dependency 'guard-bundler'
  gem.add_development_dependency 'rb-fsevent'

end