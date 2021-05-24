
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "driq/version"

Gem::Specification.new do |spec|
  spec.name          = "driq"
  spec.version       = Driq::VERSION
  spec.authors       = ["Masatoshi SEKI"]
  spec.email         = ["m_seki@mva.biglobe.ne.jp"]

  spec.summary       = %q{simple rd-stream}
  spec.description   = %q{simple rd-stream}
  spec.homepage      = "https://github.com/seki/Driq"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "test-unit", "~> 3.3"
  spec.add_development_dependency "bundler", ">= 2.2.10"
  spec.add_development_dependency "rake", "~> 12.3.3"
  spec.add_development_dependency "rspec", "~> 3.0"
end
