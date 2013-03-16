lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'ghost_dog'
require 'pry'

RSpec.configure do |config|
  config.color_enabled = true
end
