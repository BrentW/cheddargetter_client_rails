$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'rspec'
require 'active_record'
require 'cheddargetter_client_rails'

CGEmail       = "michael@expectedbehavior.com"
CGProductCode = 'GEM_TEST'
CGPassword    = "DROlOAeQpWey6J2cqTyEzH"
CGFreePlanId  = "a6a816c8-6d14-11e0-bcd4-40406799fa1e"
CGClient      = CheddarGetter::Client.new(:product_code => CGProductCode,
                               :username => CGEmail,
                               :password => CGPassword)
                               
# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  class TestUser < ActiveRecord::Base
    attr_accessor :customer_code
  end
  
  config.mock_with :rspec
  
  config.before { stub_cheddargetter }
end

def stub_cheddargetter
  CheddarGetter::Client.stub(:new).and_return CGClient
end