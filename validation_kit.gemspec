# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)
require "validation_kit/version"

Gem::Specification.new do |s|
  s.name        = "validation_kit"
  s.version     = ValidationKit::VERSION
  s.authors     = ["Wes Morgan", "Paul Schreiber"]
  s.email       = ["wes@turbovote.org", "paulschreiber@gmail.com"]
  s.homepage    = "https://github.com/turbovote/validation_kit"
  s.licenses    = ["MIT"]
  s.summary     = "Handy validations for Rails forms"
  s.description = "A collection of various validators for Rails forms"

  s.files         = `git ls-files`.split("\n") - ["Gemfile.lock"]
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.required_ruby_version = ">= 3.4"

  s.metadata["rubygems_mfa_required"] = "true"
end
