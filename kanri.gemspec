# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'kanri/version'

Gem::Specification.new do |spec|
    spec.name          = 'kanri'
    spec.version       = Kanri::VERSION
    spec.authors       = ['Matthew Lanigan']
    spec.email         = ['rintaun@gmail.com']

    spec.summary       = 'A minimalist authorization framework.'
    spec.description   = <<~DESCRIPTION
        Kanri (lit. management) is a minimalist authorization framework inspired
        by others such as Kan and Pundit. It aims to accomplish most basic
        authorization tasks in as simple a manner as possible without
        sacrificing functionality.
    DESCRIPTION
    spec.homepage      = 'https://github.com/Co-Chu/Kanri'
    spec.license       = 'MIT'

    spec.files         = Dir.chdir(File.expand_path('.', __dir__)) do
        `git ls-files -z`.split("\x0")
                         .reject { |f| f.match(%r{^(test|spec|features)/}) }
    end
    spec.bindir        = 'bin'
    spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
    spec.require_paths = ['lib']

    spec.add_development_dependency 'bundler', '~> 1.16'
    spec.add_development_dependency 'rspec', '~> 3.0'
    spec.add_development_dependency 'yard', '~> 0.9'
end
