# frozen_string_literal: true

require_relative 'lib/jellygem/version'

Gem::Specification.new do |spec|
  spec.name          = 'jellygem'
  spec.version       = Jellygem::VERSION
  spec.authors       = ['Your Name']
  spec.email         = ['your.email@example.com']

  spec.summary       = 'TV show organization tool'
  spec.description   = 'Jellygem is a command-line tool that helps organize your TV show collection ' \
                      'by detecting series names, renaming files/folders, and adding metadata for ' \
                      'Jellyfin/Kodi/Plex media centers.'
  spec.homepage      = 'https://github.com/yourusername/jellygem'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.6.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.glob('{bin,lib,config}/**/*') + %w[LICENSE README.md VERSION]
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Dependencies
  spec.add_dependency 'fileutils', '~> 1.5'
  spec.add_dependency 'httparty', '~> 0.20'
  spec.add_dependency 'yaml', '~> 0.1'

  # Development dependencies
  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 1.0'
end
