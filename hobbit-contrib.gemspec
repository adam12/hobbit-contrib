# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hobbit/contrib/version'

Gem::Specification.new do |spec|
  spec.name          = 'hobbit-contrib'
  spec.version       = Hobbit::Contrib::VERSION
  spec.authors       = ['Patricio Mac Adden']
  spec.email         = ['patriciomacadden@gmail.com']
  spec.description   = %q{Contributed Hobbit extensions}
  spec.summary       = %q{Contributed Hobbit extensions}
  spec.homepage      = 'https://github.com/patriciomacadden/hobbit-contrib'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'codeclimate-test-reporter'
  spec.add_development_dependency 'erubis'
  spec.add_development_dependency 'mote'
  spec.add_development_dependency 'oktobertest'
  spec.add_development_dependency 'rack-test'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'tilt'

  spec.add_runtime_dependency 'hobbit'
end
