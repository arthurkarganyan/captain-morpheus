require 'yaml'
require 'bundler'
Bundler.require(:default)
require 'active_support/all'

root = File.expand_path File.dirname(__FILE__)
(Dir["lib/*.rb"] + Dir["app/*.rb"]).each do |file|
  require "#{root}/#{file}"
  puts "#{root}/#{file} loaded"
end

BASE_PATH = File.expand_path(File.dirname(__FILE__)) + '/'

CONFIG = YAML.load_file(BASE_PATH + 'config.yml')

def CONFIG.[](key)
  ENV[key.to_s] || CONFIG.fetch(key.to_s) || fail("Key `#{key}` not found")
end

AFTER_FEE = 1 - 0.0025
INDICATORS = [:rsi12, :trend12, :trend24, :mavg12coef, :mavg24coef]


