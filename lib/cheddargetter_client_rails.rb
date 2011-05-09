require 'active_support'

module CheddargetterClientRails
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
