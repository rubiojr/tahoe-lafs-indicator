$: << 'lib'
require 'rake'
require './lib/tahoetray/version.rb'
require 'jeweler'

PROJECT = 'tahoe-lafs-indicator'
PROJECT_VERSION = TahoeTray::VERSION

Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.version = PROJECT_VERSION
  gem.name = PROJECT
  gem.homepage = "http://github.com/rubiojr/#{PROJECT}"
  gem.license = "MIT"
  gem.summary = %Q{Tahoe-LAFS Indicator/StatusIcon}
  gem.description = %Q{Tahoe-LAFS Indicator/StatusIcon}
  gem.email = "rubiojr@frameos.org"
  gem.authors = ["Sergio Rubio"]
end
Jeweler::RubygemsDotOrgTasks.new

task :default => :build

task :dist, :destdir do |t,args|
  destdir = (args[:destdir] || '/tmp')
  pwd = Dir.pwd
  Dir.chdir '../'
  system "tar --exclude #{PROJECT}/exclude --exclude " + \
         "#{PROJECT}/debian " + \
         "-czf #{destdir}/#{PROJECT}_#{PROJECT_VERSION}.orig.tar.gz " + \
         "#{PROJECT}"
  Dir.chdir pwd
end

task :deb, :destdir do |t, args|
  destdir = (args[:destdir] || '/tmp')
  pwd = Dir.pwd
  Dir.chdir '../'
  system "tar --exclude #{PROJECT}/exclude --exclude " + \
         "#{PROJECT}/debian " + \
         "-czf #{destdir}/#{PROJECT}_#{PROJECT_VERSION}.orig.tar.gz " + \
         "#{PROJECT}"
  Dir.chdir "#{destdir}"
  system "tar xzf #{PROJECT}_#{PROJECT_VERSION}.orig.tar.gz"
  Dir.chdir pwd
  system "cp -r debian #{destdir}/#{PROJECT}/"
end
