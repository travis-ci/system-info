lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'system_info/version'

Gem::Specification.new do |spec|
  spec.name = 'travis-system-info'
  spec.version = SystemInfo::VERSION
  spec.authors = ['Hiro Asari', 'Dan Buch']
  spec.email = ['hiro@travis-ci.org', 'dan@travis-ci.org']

  spec.summary = 'Gather and report system info for the Travis build env.'
  spec.description = 'Gather and report system info for the Travis build env, really!'
  spec.homepage = 'https://github.com/travis-ci/system_info'
  spec.license = 'MIT'

  spec.files = `git ls-files -z`.split("\x0").reject do
    |f| f.match(%r{^(test|spec|features)/})
  end

  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = %w(lib)

  spec.add_development_dependency 'bundler', '~> 1.10'
  spec.add_development_dependency 'pry', '~> 0'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3'
  spec.add_development_dependency 'rubocop', '~> 0'
  spec.add_development_dependency 'simplecov', '~> 0'
end
