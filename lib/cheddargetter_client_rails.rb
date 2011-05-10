require 'active_support'
require 'cheddargetter_client_ruby'

module CheddargetterClientRails
  autoload :Subscription, 'cheddargetter_client_rails/subscription'
  
  def self.included(base)
    base.extend ClassMethods
    
    def subscription
      @subscription ||= Subscription.new
    end
    
    def validate_subscription
       if !skip_cheddargetter && new_record? && !subscription.valid?
         errors.add(:subscription, 'problem')
       end
    end
    
    def new_record?
      true
    end
    
    def skip_cheddargetter
      false
    end    
  end
  
  module ClassMethods
    def cheddargetter_billable_on(*args)
      if args.length > 0
        self.customer_code_column = args.shift
        
        if args.length > 0
          self.shared_columns = args.shift[:shared_columns]
        end
      else
        raise ArgumentError.new('Must supply customer code column.')
      end
      
      validate :validate_subscription      
    end

    def customer_code_column
      @customer_code_column
    end
  
    def customer_code_column=(column)
      @customer_code_column = column
    end
    
    def shared_columns
      @shared_columns
    end
    
    def shared_columns=(columns)
      @shared_columns = columns
    end    
  end
end

class ActiveRecord::Base
  include CheddargetterClientRails
end
