# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'i18n/assets/version'

Gem::Specification.new do |spec|
  spec.name          = "i18n-assets"
  spec.version       = I18n::Assets::VERSION
  spec.authors       = ["Maxim Gladkov"]
  spec.email         = ["contact@maximgladkov.com"]
  spec.summary       = %q{Rails assets localization made easy}
  spec.description   = %q{Ever wanted to use rails localization helpers inside your assets? Your dream just came true!}
  spec.homepage      = "https://github.com/maximgladkov/i18n-assets"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"

  spec.add_dependency 'sprockets', "~> 2.2.2"
end
