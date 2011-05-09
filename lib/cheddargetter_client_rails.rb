require 'active_support'
require 'cheddargetter_client_ruby'

module CheddargetterClientRails
  autoload :Subscription, 'cheddargetter_client_rails/subscription'
  
  def self.included(base)
    base.extend ClassMethods
  end

  
  module ClassMethods
    def cheddargetter_billable_on(*args)
    end
    
  end
end

class ActiveRecord::Base
  include CheddargetterClientRails
end
