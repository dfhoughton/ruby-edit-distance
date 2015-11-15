# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'edit_distance/version'

Gem::Specification.new do |spec|
  spec.name          = "edit_distance"
  spec.version       = EditDistance::VERSION
  spec.authors       = ["dfhoughton"]
  spec.email         = ["dfhoughton@gmail.com"]

  spec.summary       = %q{Pluggable edit distance framework based on Levenshtein algorithm.}
  spec.description   = <<-END
                        EditDistance provides the framework to write insertion/deletion/substitution-based edit
                        distance algorithms backed by the Levenshtein edit distance dynamic programming framework.
                        In addition to a distance metric, it can provide a description of the sequence of edits a
                        particular distance corresponds to.
                        END
  spec.homepage      = "https://github.com/dfhoughton/ruby-edit-distance"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5"
  spec.add_development_dependency 'pry-byebug'
end
