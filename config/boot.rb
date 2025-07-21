require 'logger'
puts "Logger defined in boot.rb? #{defined?(Logger)}"

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.
