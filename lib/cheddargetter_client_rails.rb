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
    
    def supplement_subscription_fields
      self.class.shared_columns.each do |subscription_column, user_attribute|
        if(subscription_column == :planCode && user_attribute.is_a?(String)) #user can specify planCode as a string
          subscription.send(subscription_column.to_s + '=', user_attribute)
        else
          subscription.send(subscription_column.to_s + '=', send(user_attribute))
        end
      end
    end
    
    def create_subscription
      subscription.customerCode = send(self.class.customer_code_column) if !subscription.customerCode
      subscription.create unless skip_cheddargetter
    end
    
    def current_subscription
      @current_subscription ||= CheddargetterClientRails::Subscription.get(customer_code)
    end
    
    def destroy_subscription
      current_subscription.try(:destroy)
    end
  end
  
  module ClassMethods
    def cheddargetter_billable_on(*args)
      raise ArgumentError.new('Must supply customer code column.') if args.length < 1
      self.customer_code_column = args.shift
      raise ArgumentError.new("Record does not respond to #{customer_code_column.to_s}.") if !self.instance_methods.include?(customer_code_column.to_s)        
      
      if args.length > 0
        self.shared_columns = args.shift[:shared_columns]
      end
      
      attr_accessor :skip_cheddargetter
      
      validate        :validate_subscription
      after_create   :create_subscription
      before_destroy  :destroy_subscription           
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
