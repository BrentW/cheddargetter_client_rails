# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "cheddargetter_client_rails"
  gem.homepage = "http://github.com/BrentW/cheddargetter_client_rails"
  gem.license = "MIT"
  gem.summary = %Q{Integrates CheddarGetter api with Active Record}
  gem.description = %Q{Integrates CheddarGetter api with Active Record. Uses cheddargetter_client_ruby.}
  gem.email = "brent.wooden@gmail.com"
  gem.authors = ["Brent Wooden"]

  gem.add_dependency "cheddargetter_client", ">= 0.0.2"
  gem.add_dependency 'country_select', '>= 1.1.3'

  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :default => :spec

