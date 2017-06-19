$LOAD_PATH.unshift(File.expand_path("../lib", __FILE__))

require "rufka/version"

Gem::Specification.new do |s|
  s.name        = "rufka"
  s.version     = Rufka::VERSION
  s.authors     = ["Agis Anastasopoulos"]
  s.email       = ["agis.anast@gmail.com"]
  s.homepage    = "https://github.com/skroutz/rufka"
  s.summary     = "Ruby client for Rafka"
  s.description = "A Ruby client for Rafka, providing consumer " \
    "and producer implementations."
  s.license     = "MIT"

  s.files = Dir["{lib,test}/**/*", "CHANGELOG.md", "LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "redis", "~> 3.3"

  s.add_development_dependency "pry-byebug"
end
