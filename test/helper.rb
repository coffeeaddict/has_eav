require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'test/unit'
require 'shoulda'

ENV['RAILS_ENV'] = 'test'
ENV['RAILS_ROOT'] = File.dirname(__FILE__)
 
require 'test/unit'
require File.expand_path(File.join(ENV['RAILS_ROOT'], 'config/environment.rb'))

path = File.expand_path("db/migrate", File.dirname(__FILE__))
$stderr.puts "Migrating #{path}"
ActiveRecord::Migrator.migrate path, nil
    
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

class Test::Unit::TestCase
end

