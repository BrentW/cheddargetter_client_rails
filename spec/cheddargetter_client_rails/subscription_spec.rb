require 'spec_helper'

describe CheddargetterClientRails::Subscription do
  let(:user)          { double("TestUser") }
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
      CGClient.should_receive(:new_customer) 
    }
    
    it      { subject }
  end
  
  describe 'subscription#update' do
    subject { subscription.update }
    before  { 
      subscription.stub(:add_errors_or_return_valid_response).and_return true      
      subscription.should_receive(:add_errors_or_return_valid_response) 
      CGClient.should_receive(:edit_customer)
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
      before  { subscription.should_receive(:update) }
      it      { subject }
    end

    context 'when a subscription already exists' do
      before  { CheddargetterClientRails::Subscription.stub(:new_record?).and_return true }
      before  { subscription.should_receive(:create) }
      it      { subject }
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
      context 'when customerCode is not set' do
        before { subscription.customerCode = nil }
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
end