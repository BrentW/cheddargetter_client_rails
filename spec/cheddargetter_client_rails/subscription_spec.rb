require 'spec_helper'

describe CheddargetterClientRails::Subscription do
  before { ActiveRecord::Base.stub(:connection).and_return mock(:columns => [], :table_exists? => 'true') }

  before {
    class TestUser < ActiveRecord::Base
      attr_accessor :customer_code, :first_name, :last_name, :plan_code, :email

      def self.column_names
        []
      end
            
      has_subscription :customerCode => :customer_code,
                                :firstName    => :first_name, 
                                :lastName     => :last_name, 
                                :ccFirstName  => :first_name, 
                                :ccLastName   => :last_name, 
                                :planCode     => :plan_code
                                              
    end
  }
  
  
  let(:user)          { TestUser.new }
  let(:subscription)  { CheddargetterClientRails::Subscription.new }
  let(:customer_code) { 'JOHN_DOE' }

  let(:valid_subscription_attributes) {
    {
      :planCode     => 'PAID_PLAN',
      :firstName    => 'Joe',
      :lastName     => 'Collins',
      :ccNumber     => '4111111111111111',
      :ccExpiration => '04/' + 3.years.from_now.year.to_s,
      :zip          => '47401',
      :email        => 'jim@test.com'
    }
  }

  before { 
    user.should_receive(:customer_code=).with(customer_code)
    user.customer_code = subscription.customerCode = customer_code
  }
  
  describe 'subscription#create' do
    subject { subscription.create }
    before  { 
      subscription.stub(:add_errors_or_return_valid_response).and_return true
      subscription.should_receive(:add_errors_or_return_valid_response)    
      CGClient.should_receive(:customers_new) 
    }
    
    it      { subject }
  end
  
  describe 'subscription#update' do
    subject { subscription.update }
    before  { 
      subscription.stub(:add_errors_or_return_valid_response).and_return true      
      subscription.should_receive(:add_errors_or_return_valid_response) 
      CGClient.should_receive(:customers_edit)
    }
    
    it      { subject }
  end
  
  describe 'subscription#new_record?' do
    subject { subscription.new_record? }
    
    context 'when a subscription already exists' do
      before  { CheddargetterClientRails::Subscription.stub(:get).and_return true }
      it      { should be(false) }
    end

    context 'when no subscription exists' do
      before  { CheddargetterClientRails::Subscription.stub(:get).and_return false }
      it      { should be(true) }
    end
  end
  
  describe 'subscription#save' do
    subject { subscription.save }
    
    context 'when a subscription already exists' do
      before  { subscription.stub(:new_record?).and_return false }
      before  { valid_subscription_attributes.each {|attribute, value| subscription.send(attribute.to_s + '=', value )} }      
      before  { subscription.should_receive(:update) }
      it      { subject }
    end

    context 'when a subscription already exists' do
      before  { CheddargetterClientRails::Subscription.stub(:new_record?).and_return true }
      before  { valid_subscription_attributes.each {|attribute, value| subscription.send(attribute.to_s + '=', value )} }
      before  { subscription.should_receive(:create) }
      it      { subject }
    end
    
    context 'when not valid' do
      before  { CheddargetterClientRails::Subscription.stub(:new_record?).and_return true }
      
      specify { subject; (subscription.errors.length > 1).should be_true }
    end    
  end
  
  describe 'subscription#destroy' do
    subject { subscription.destroy }
    context 'without customerCode' do
      before { subscription.customerCode = nil }
      specify { lambda{subject}.should raise_error }
    end
    
    context 'with customerCode' do
      specify { lambda{subject}.should_not raise_error }
    end
  end
  
  describe 'validates_presence_of' do
    # this tests validations
    #
    # validates_presence_of :firstName,
    #                       :lastName,
    #                       :email,
    #                       :customerCode,
    #                       :planCode
    # 
    # validates_presence_of :ccNumber,
    #                       :ccExpiration,
    #                       :zip, :if => :paid_plan?

    subject { subscription.valid? }
    before  { valid_subscription_attributes.each{ |attribute, value| subscription.send(attribute.to_s + '=', value) } }
     
    context 'when free plan' do
      before { subscription.planCode = "FREE_PLAN" }
      
      context 'when firstName is not set' do
        before { subscription.firstName = nil }
        it { should be_false }
      end
      context 'when lastName is not set' do
        before { subscription.lastName = nil }
        it { should be_false }
      end
      context 'when email is not set' do
        before { subscription.email = nil }
        it { should be_false }
      end
      context 'when planCode is not set' do
        before { subscription.planCode = nil }
        it { should be_false }
      end
      context 'when ccNumber is not set' do
        before { subscription.ccNumber = nil }
        it { should be_true }
      end
      context 'when ccExpiration is not set' do
        before { subscription.ccExpiration = nil }
        it { should be_true }
      end
      context 'when zip is not set' do
        before { subscription.zip = nil }
        it { should be_true }
      end    
    end
    
    context 'when paid plan' do
      context 'when firstName is not set' do
        before { subscription.firstName = nil }
        it { should be_false }
      end
      context 'when lastName is not set' do
        before { subscription.lastName = nil }
        it { should be_false }
      end
      context 'when email is not set' do
        before { subscription.email = nil }
        it { should be_false }
      end
      context 'when planCode is not set' do
        before { subscription.planCode = nil }
        it { should be_false }
      end
      context 'when ccNumber is not set' do
        before { subscription.ccNumber = nil }
        it { should be_false }
      end
      context 'when ccExpiration is not set' do
        before { subscription.ccExpiration = nil }
        it { should be_false }
      end
      context 'when zip is not set' do
        before { subscription.zip = nil }
        it { should be_false }
      end      
    end
  end
  
  describe 'instance_variables_hash' do
    before  { valid_subscription_attributes.each {|attribute, value| subscription.send(attribute.to_s + '=', value )} }
    before  { 
      subscription.customerCode = "CUSTOMER_CODE" 
      subscription.ccFirstName  = "Joe"
      subscription.ccLastName   = "Collins"
    }      
    subject { subscription.instance_variables_hash }
    it {
      should eq({
        :planCode     => 'PAID_PLAN',
        :firstName    => 'Joe',
        :lastName     => 'Collins',
        :ccFirstName    => 'Joe',
        :ccLastName     => 'Collins',
        :zip          => '47401',
        :email        => 'jim@test.com',
        :customerCode => 'CUSTOMER_CODE'
      })
    }
  end
  
  describe 'to_key' do
    subject { subscription.to_key }
    it { should eq(nil) }
  end
  
  describe 'subscription_fields_present?' do
    subject { user.subscription.fields_present? }
    
    context 'when they are not present' do
      it { should be_false }
    end
    
    context 'when one is and it is nil' do
      before { user.subscription.firstName = nil }
      it { should be_false }
    end
    
    context 'when is and it is not nil' do
      before { user.subscription.firstName = 'Joe' }
      it { should be_true }
    end
  end

  describe 'ccExpirationMonth=(month)' do
    let(:month) { '44' }
    subject { user.subscription.ccExpiration }

    context "when there is a value in ccExpiration" do
      context 'when it is already in valid MM/YYYY format' do
        before { user.subscription.ccExpiration = "44/4444"}
        before { user.subscription.ccExpirationMonth = month }
        it { should eq('44/4444')}
      end

      context 'when it is /YYYY format' do
        before { user.subscription.ccExpiration = "/4444"}
        before { user.subscription.ccExpirationMonth = month }
        it { should eq('44/4444')}
      end

      context 'when it is in an odd format' do
        before { user.subscription.ccExpiration = "ase"}
        before { user.subscription.ccExpirationMonth = month }
        it { should eq('44/')}        
      end

      context 'when it is already in valid month format' do
        before { user.subscription.ccExpiration = "33/"}
        before { user.subscription.ccExpirationMonth = month }
        it { should eq('44/')}        
      end
    end

    context 'when there is not a value in ccExpiration' do
      before { user.subscription.ccExpiration = ""}
      before { user.subscription.ccExpirationMonth = month }
      it { should eq('44/')}      
    end
  end

  describe'ccExpirationYear=(year)' do
    let(:year) { '4444' }
    subject { user.subscription.ccExpiration }

    context "when there is a value in ccExpiration" do
      context 'when it is already in valid MM/YYYY format' do
        before { user.subscription.ccExpiration = "44/4444"}
        before { user.subscription.ccExpirationYear = year }
        it { should eq('44/4444')}
      end

      context 'when it is in MM/ format' do
        before { user.subscription.ccExpiration = "44/"}
        before { user.subscription.ccExpirationYear = year }
        it { should eq('44/4444')}
      end

      context 'when it is in an odd format' do
        before { user.subscription.ccExpiration = "ase"}
        before { user.subscription.ccExpirationYear = year }
        it { should eq('/4444')}        
      end

      context 'when it is already in valid year format' do
        before { user.subscription.ccExpiration = "/4444"}
        before { user.subscription.ccExpirationYear = year }
        it { should eq('/4444')}        
      end
    end

    context 'when there is not a value in ccExpiration' do
      before { user.subscription.ccExpiration = ""}
      before { user.subscription.ccExpirationYear = year }
      it { should eq('/4444')}      
    end

  end

  describe 'expiration_in_valid_format?' do
    subject { user.subscription.expiration_in_valid_format? }
    context 'when in valid format' do
      before { user.subscription.ccExpiration = "44/4444"}
      it { should be_true }
    end

    context 'when not in valid format' do
      context 'with just month' do
        before { user.subscription.ccExpiration = "44/"}
        it { should be_false }

      end

      context 'with just year' do
        before { user.subscription.ccExpiration = "/4444"}
        it { should be_false }
      end

      context 'with odd thigns' do
        before { user.subscription.ccExpiration = "4a/3333"}
        it { should be_false }
      end

      context 'when blank' do
        before { user.subscription.ccExpiration = ""}
        it { should be_false }
      end
    end

  end

  describe 'expiration_in_valid_month_format?' do
    subject { user.subscription.expiration_in_valid_month_format? }

    context 'when in valid format' do
      before { user.subscription.ccExpiration = '44/'}
      it { should be_true }
    end

    context 'when not in valid_format' do
      context 'with junk' do
        before { user.subscription.ccExpiration = 'asefas'}
        it { should be_false }
      end

      context 'when blank' do
        before { user.subscription.ccExpiration = ''}
        it { should be_false }
      end

      context 'with full date' do
        before { user.subscription.ccExpiration = '44/4444'}
        it { should be_false }
      end
    end
  end

  describe 'expiration_in_valid_year_format?' do
    subject { user.subscription.expiration_in_valid_year_format? }

    context 'when in valid format' do
      before { user.subscription.ccExpiration = '/4444'}
      it { should be_true }
    end

    context 'when not in valid_format' do
      context 'with junk' do
        before { user.subscription.ccExpiration = 'asefas'}
        it { should be_false }
      end

      context 'when blank' do
        before { user.subscription.ccExpiration = ''}
        it { should be_false }
      end

      context 'with full date' do
        before { user.subscription.ccExpiration = '44/4444'}
        it { should be_false }
      end
    end
  end
end