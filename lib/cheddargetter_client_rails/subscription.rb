module CheddargetterClientRails
  class Subscription
    include ActiveModel::Validations

    Months = ("01".."12").freeze
    Years  = (Date.current.year..Date.current.year+10).collect{|y| y.to_s }.freeze
    CGKeys =  [   
      :planCode,
      :company,
      :firstName,
      :lastName,
      :ccFirstName,
      :ccLastName,
      :ccExpiration,
      :ccNumber,
      :ccLastFour,
      :ccCountry,
      :ccAddress,
      :ccCity,
      :ccState,
      :customerCode,
      :email,
      :zip    
    ]
  
  
    attr_accessor :planCode,
                  :company,
                  :firstName,
                  :lastName,
                  :ccFirstName,
                  :ccLastName,
                  :ccExpiration,
                  :ccNumber,
                  :ccLastFour,
                  :ccCountry,
                  :ccAddress,
                  :ccCity,
                  :ccState,
                  :customerCode,
                  :email,
                  :zip,
                  :ccExpirationMonth,
                  :ccExpirationYear

    validates_presence_of :firstName,
                          :lastName,
                          :email,
                          :planCode
                          #:customerCode, generally we call valid before unique identifier is called

    validate :unexpired
  
    validate :validates_presence_of_humanized

    validates_presence_of :ccNumber,
                      :ccExpiration,
                      :zip, :if => :paid_plan?
  
    def paid_plan?
      if planCode
        plans = CGClient.plans_get
        !plans.plan(planCode)[:isFree]
      end
    end

    def unexpired
      if ccExpiration.present?
        month, year = ccExpiration.split("/").collect{|string| string.to_i }
        year  = ('20' + year.to_s).to_i if year.size < 4
        month = ('0' + month.to_s).to_i if month.size < 2

        if Date.civil(year, month + 1) <= Date.today
          errors.add(:ccExpiration, 'has been reached')
        end
      end
    end

    def validates_presence_of_humanized
      if planCode.blank?
        self.errors.add(:base, 'You must select a billing plan')
      end
    end

    def initialize(hash = {})
      hash.each { |k, v| send("#{k}=", v) }
    end
  
    def self.get(customer_code)
      response = CGClient.customers_get(:customer_code => customer_code)

      if response.errors.blank?
        build_from_response(response)
      end
    end

    def self.build_from_response(response)
      customer_subscription = response.try(:customer_subscription)
      customer_plan         = response.try(:customer_plan)
    
      if customer_plan and customer_subscription
        new(
          :firstName    => response.customer[:firstName],
          :lastName     => response.customer[:lastName],
          :email        => response.customer[:email],
          :ccLastFour   => customer_subscription[:ccLastFour], 
          :ccFirstName    => customer_subscription[:ccFirstName],
          :ccLastName     => customer_subscription[:ccLastName],
          :planCode     => customer_plan[:code],
          :zip          => customer_subscription[:ccZip],
          :ccExpiration => customer_subscription[:ccExpirationDate],
          :customerCode => response.customer[:code]        
        )
      end
    end
  
    def new_record?
      !CheddargetterClientRails::Subscription.get(customerCode)
    end
  
    def save
      return false if !valid?
      
      if new_record?
        create
      else
        update
      end
    end
  
    def create
      response = CGClient.customers_new(
        :customer_code      => customerCode,
        :firstName => firstName,
        :lastName  => lastName,
        :email     => email,
        :subscription => {
          :planCode     => planCode,
          :ccFirstName  => ccFirstName,
          :ccLastName   => ccLastName,
          :ccNumber     => ccNumber,
          :ccExpiration => ccExpiration,
          :ccZip        => zip
        }
      )    

      add_errors_or_return_valid_response(response)
    end

    def add_errors_or_return_valid_response(response)
      #this returns cheddargetter errors.
      #hopefully most errors are handled before this in the valid? calls
      #which return prettier errors, but inevitably some will not be caught.
      if response.try(:errors).try(:any?)
        response.errors.each do |error|
          errors.add(:base, error[:text])
        end
      
        return false
      else
        response
      end    
    end

    def update
      response = CGClient.customers_edit(
        {:customer_code      => customerCode},
        {
          :firstName => firstName,
          :lastName  => lastName,
          :email     => email,
          :subscription => {
            :planCode     => planCode,
            :ccFirstName  => ccFirstName,
            :ccLastName   => ccLastName,
            :ccNumber     => ccNumber,
            :ccExpiration => ccExpiration,
            :ccZip        => zip
          }
        }
      )    

      add_errors_or_return_valid_response(response)
    end
  
    def destroy
      raise "Invalid customer code" if customerCode.blank?
      response = CGClient.customers_delete({ :code => customerCode })
    
      add_errors_or_return_valid_response(response)    
    end
    
    def instance_variables_hash
      {
        :customerCode => customerCode, 
        :firstName => firstName,
        :ccLastName => ccLastName,
        :ccFirstName => ccFirstName,
        :planCode => planCode,
        :zip => zip,
        :lastName => lastName,
        :email => email
      }     
    end
    
    def to_key
      nil
    end
    
    def fields_present?
      CGKeys.collect do |key|
        val = send(key)
        val if val.present?
      end.compact.present?
    end

    def ccExpirationMonth=(month)
      if !expiration_in_valid_format? && expiration_in_valid_year_format?
        @ccExpiration = month + ccExpiration
      elsif !expiration_in_valid_format?
        @ccExpiration = (month + '/')
      end
    end

    def ccExpirationYear=(year)
      if !expiration_in_valid_format? && expiration_in_valid_month_format?
        @ccExpiration = ccExpiration + year
      elsif !expiration_in_valid_format?
        @ccExpiration = ('/' + year)
      end
    end

    def expiration_in_valid_format?
      ccExpiration.match(/^\d\d\/\d\d\d\d$/)
    end

    def expiration_in_valid_month_format?
      ccExpiration.match(/^\d\d\/$/)
    end

    def expiration_in_valid_year_format?
      ccExpiration.match(/^\/\d\d\d\d$/)
    end
  end
end