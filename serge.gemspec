# frozen_string_literal: true

require_relative "lib/serge/version"

Gem::Specification.new do |spec|
  spec.name = "serge"
  spec.version = Serge::VERSION
  spec.licenses    = ['MIT']
  spec.authors = ["Tom Brown"]
  spec.email = ["herestomwiththeweather@gmail.com"]

  spec.summary = "Ruby HTTP Signature for Fedi Inbox Deliveries"
  spec.description = "Accommodates both http signature formats in use on the fediverse for inbox deliveries"
  spec.homepage = "https://github.com/herestomwiththeweather/serge"
  spec.required_ruby_version = ">= 3.0.0"

  #spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  #spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  #spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "activesupport", ">= 7.1", "< 9"
  spec.add_dependency "linzer", "~> 0.8"
  spec.add_dependency "rack", "~> 3.2"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
