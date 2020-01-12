require_relative './lib/version'

Gem::Specification.new do |gem|
  gem.name         = 'poe-watch-api'
  gem.version      = PoeWatch::VERSION
  gem.date         = '2019-01-13'
  gem.summary      = 'Ruby Poe Watch API wrapper.'
  gem.description  = 'Ruby Poe Watch API wrapper.'
  gem.authors      = ['GabrielDehan']
  gem.email        = 'dehan.gabriel@gmail.com'
  gem.homepage     = 'https://github.com/gabriel-dehan/poe-watch-api'
  gem.files        = Dir["{lib}/**/*.rb", "LICENSE", "*.md"]
  
  gem.add_dependency "redis", ">= 4.1.0"

  gem.require_path = "lib"
end