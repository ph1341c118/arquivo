# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'arquivo/version'

Gem::Specification.new do |spec|
  spec.name          = 'arquivo'
  spec.version       = Arquivo::VERSION
  spec.authors     = ['Hernâni Rodrigues Vaz']
  spec.email       = ['hernanirvaz@gmail.com']
  spec.homepage    = 'https://github.com/ph1341c118/arquivo'

  spec.summary       = 'Write a short summary, because RubyGems requires one.'
  spec.description   = ' Write a longer description or delete this line.'
  spec.license       = 'MIT'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['yard.run'] = 'yard'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the
  # RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0")
                     .reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.17'
  spec.add_development_dependency 'rake', '~> 10.0'

  spec.add_dependency 'fastimage', '~> 2.1'
  spec.add_dependency 'google-api-client', '~> 0.34'
  spec.add_dependency 'pdf-reader', '~> 2.3'
  spec.add_dependency 'thor', '~> 0.1'
end
