# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "mr/version"

Gem::Specification.new do |gem|
  gem.name        = "mr"
  gem.version     = MR::VERSION
  gem.authors     = ["Kelly Redding", "Collin Redding"]
  gem.email       = ["kelly@kellyredding.com", "collin.redding@me.com"]
  gem.description = %q{Model-record pattern}
  gem.summary     = %q{Model-record pattern}
  gem.homepage    = "http://github.com/redding/mr"
  gem.license     = 'MIT'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency("ns-options",    ["~> 1.1"])
  gem.add_dependency("activerecord",  ["~> 3.2"])
  gem.add_dependency("activesupport", ["~> 3.2"])

  gem.add_development_dependency("assert",       ["~> 2.2"])
  gem.add_development_dependency("assert-mocha", ["~> 1.0"])
  gem.add_development_dependency("sqlite3",      ["~> 1.3"])

end
