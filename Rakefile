begin
  require "bundler/setup"
rescue LoadError
  puts "You must `gem install bundler` and `bundle install` to run rake tasks"
end


gemfile_name = File.basename(ENV["BUNDLE_GEMFILE"], ".gemfile")

require "rake/testtask"
Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.pattern = "test/**/*_test.rb"
  t.verbose = true
end

require "yard"
YARD::Rake::YardocTask.new do |t|
  t.files   = ["lib/**/*.rb"]
end

require "rubocop/rake_task"
RuboCop::RakeTask.new

task default: [:test, :rubocop]
