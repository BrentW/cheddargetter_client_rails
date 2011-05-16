require 'active_support'
require 'action_controller/record_identifier'
require 'cheddargetter_client_ruby'
require 'rails/record_identifier'
require 'rails/naming'

module CheddargetterClientRails
  autoload :Subscription, 'cheddargetter_client_rails/subscription'
  
  def self.included(base)
    base.extend ClassMethods
    
    def subscription
      @subscription ||= Subscription.new
    end
    
    def subscription=(value)
      @subscription = value
    end
    
    def validate_subscription
       supplement_subscription_fields
       
       if !skip_cheddargetter && new_record? && !subscription.valid?
         errors.add(:subscription, 'problem')
       end
    end
    
    def supplement_subscription_fields
      if subscription.is_a?(ActiveSupport::HashWithIndifferentAccess)
        self.subscription = CheddargetterClientRails::Subscription.new(subscription)
      end
      
      self.class.shared_columns.each do |subscription_column, user_attribute|
        if(subscription_column == :planCode && user_attribute.is_a?(String)) #user can specify planCode as a string
          subscription.send(subscription_column.to_s + '=', user_attribute)
        else
          subscription.send(subscription_column.to_s + '=', send(user_attribute))
        end
      end
    end
    
    def create_subscription
      raise ArgumentError, 'Customer code is not set on record.' if !customer_code_column_value && !subscription.customerCode
      subscription.customerCode = customer_code_column_value if !subscription.customerCode
      subscription.create unless skip_cheddargetter
    end
        
    def current_subscription
      @current_subscription ||= CheddargetterClientRails::Subscription.get(customer_code_column_value) if customer_code_column_value
    end
    
    def destroy_subscription
      current_subscription.try(:destroy)
    end

    def customer_code_column_value
      if self.class.send(:customer_code_column)
        value = send(self.class.send(:customer_code_column))
        value.to_s if value.try(:to_s).present?
      end 
    end
    
    def build_subscription(attributes_hash)
      # set attributes from current cheddargetter subscription, then
      # replaces any values with supplied data
      new_subscription = CheddargetterClientRails::Subscription.new
      if old_subscription = current_subscription
        old_subscription.instance_variables_hash.each do |key, value|
          new_subscription.send(key.to_s + '=', value)
        end
      end
      
      attributes_hash.each do |key, value|
        new_subscription.send(key.to_s + '=', value)
      end
      
      self.subscription = new_subscription
      new_subscription
    end
    
    def save_subscription(attributes_hash)
      build_subscription(attributes_hash)
      subscription.save
    end
  end
  
  module ClassMethods
    def has_subscription(args = {})
      self.customer_code_column = args.delete(:customerCode) || :id
      raise ArgumentError.new("Record does not respond to #{customer_code_column.to_s}.") if !responds_to_customer_code_column?        
      
      shared = {}
      shared[:email]      = args.delete(:email)      || :email
      shared[:firstName]  = args.delete(:firstName)  || :first_name
      shared[:lastName]   = args.delete(:lastName)   || :last_name
      shared[:planCode]   = args.delete(:planCode)   || :plan_code
      
      args.each do |key, value|
        shared[key] = value
      end
      
      self.shared_columns = shared
      
      attr_accessor :skip_cheddargetter
      
      validate        :validate_subscription
      after_create    :create_subscription
      before_destroy  :destroy_subscription           
    end

    def responds_to_customer_code_column?
      self.instance_methods.include?(customer_code_column.to_s) || 
      self.column_names.include?(customer_code_column.to_s)      
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