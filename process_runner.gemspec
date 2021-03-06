
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "process_runner/version"

Gem::Specification.new do |spec|
  spec.name          = "process_runner"
  spec.version       = ProcessRunner::VERSION
  spec.authors       = ["Michael Parrish"]
  spec.email         = ["parrish@users.noreply.github.com"]

  spec.summary       = ""
  spec.description   = ""
  spec.license       = "MIT"

  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "concurrent-ruby"
  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.0"
end
