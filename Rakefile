begin
  require 'yaml'
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = "acrylic"
    # s.executables = "acrylic"
    s.summary = "Photoshop for cool people."
    # s.email = ""
    s.homepage = "http://github.com/dotjerky/acrylic"
    s.description = "A set of image manipulation tools built on top of Cairo"
    s.authors = ["Austin Taylor", "Paul Nicholson"]
    s.files =  FileList["[A-Z]*", "{bin,lib,test}/**/*", "ext/**/*.{c,rb}"]
    s.extensions = FileList["ext/**/extconf.rb"]
    s.add_dependency('activesupport')
  end
rescue LoadError
  puts "Jeweler, or one of its dependencies, is not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

Rake::TestTask.new(:default) do |t|
  t.libs << "test"
  t.pattern = 'test/**/*_test.rb'
end