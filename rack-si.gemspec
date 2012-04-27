# -*- encoding: utf-8 -*-
require File.expand_path('../lib/rack/si/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'rack-si'
  s.version     = Rack::SI::VERSION
  s.author      = 'Derek Kastner'
  s.email       = ['dkastner@gmail.com']
  s.summary     = 'Convert any measurement params to base SI units'
  s.description = 'Choose params that are converted with Herbalist to base SI units (meters, grams, etc)'
  s.homepage    = 'https://github.com/brighterplanet/carbon'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ["lib"]

  #s.add_runtime_dependency 'herbalist'
  s.add_runtime_dependency 'rack'

  s.add_development_dependency 'rack-test'
  s.add_development_dependency 'rspec'
end
