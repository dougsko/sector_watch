# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "sector_watch/version"

Gem::Specification.new do |spec|
  spec.name          = "sector_watch"
  spec.version       = SectorWatch::VERSION
  spec.authors       = ["Doug Prostko"]
  spec.email         = ["dprostko@tripadvisor.com"]

  spec.summary       = %q{Helps with sector rotation.}
  spec.description   = %q{Helps with sector rotation.}
  spec.homepage      = "http://foo.com"


  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
