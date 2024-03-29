require_relative 'lib/graphql/autotest/version'

Gem::Specification.new do |spec|
  spec.name          = "graphql-autotest"
  spec.version       = GraphQL::Autotest::VERSION
  spec.authors       = ["Masataka Pocke Kuwabara"]
  spec.email         = ["kuwabara@pocke.me"]

  spec.summary       = %q{Test GraphQL queries automatically}
  spec.description   = %q{Test GraphQL queries automatically}
  spec.homepage      = "https://github.com/bitjourney/graphql-autotest"
  spec.required_ruby_version = Gem::Requirement.new(">= 3.0.0")
  spec.license       = 'MIT'

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/bitjourney/graphql-autotest/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'graphql'
end
