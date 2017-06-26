$LOAD_PATH.unshift(File.expand_path("../lib", __FILE__))

require "rafka/version"

Gem::Specification.new do |s|
  s.name        = "rafka"
  s.version     = Rafka::VERSION
  s.authors     = ["Agis Anastasopoulos"]
  s.email       = ["agis.anast@gmail.com"]
  s.homepage    = "https://github.com/skroutz/rafka-rb"
  s.summary     = "Ruby driver for Rafka"
  s.description = "A Ruby client library for Rafka, with consumer " \
    "and producer implementations."
  s.license     = "MIT"
  s.files = Dir["{lib,test}/**/*", "CHANGELOG.md", "LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "redis", "~> 3.3"
  s.add_development_dependency "pry-byebug"
end