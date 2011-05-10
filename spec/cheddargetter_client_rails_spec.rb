require File.expand_path(File.dirname(__FILE__) + '/spec_helper')



describe "CheddargetterClientRails" do
  let (:load_test_user_class) {
    class TestUser < ActiveRecord::Base
      attr_accessor :customer_code, :first_name, :last_name, :plan_code
      
      cheddargetter_billable_on :customer_code, :shared_columns => {
                                                  :firstName    => :first_name, 
                                                  :lastName     => :last_name, 
                                                  :ccFirstName  => :first_name, 
                                                  :ccLastName   => :last_name, 
                                                  :planCode     => :plan_code
                                                }
    end
  }
  
  let(:test_user_class) {
    TestUser
  }
  
  describe 'module included?' do
    subject { CheddargetterClientRails }
    specify { lambda { subject }.should_not raise_error }
  end
  
  describe "inclusion of class methods" do
    before { load_test_user_class }
    let(:user_class) { TestUser } 

    subject { user_class.respond_to?(:cheddargetter_billable_on) }
    
    it { should be_true }
  end
  
  describe 'cheddargetter_billable_on' do
    context 'argument errors' do
      context 'without customer code column' do
        subject {
          class NoCustomerCodeUser < ActiveRecord::Base
            cheddargetter_billable_on
          end
        }
      
        specify { lambda { subject }.should raise_error(ArgumentError) }
      end 

      context 'with customer code column' do
        subject { load_test_user_class }
        specify { lambda { subject }.should_not raise_error }
      end
    end
    
    context 'setting customer_code_column' do
      before { load_test_user_class }
      subject { test_user_class.customer_code_column }
      it { should eq(:customer_code) }
    end
    
    context 'setting shared_columns' do
      before { load_test_user_class }
      subject { test_user_class.shared_columns }
      it { should eq( :firstName    => :first_name, 
                      :lastName     => :last_name, 
                      :ccFirstName  => :first_name, 
                      :ccLastName   => :last_name, 
                      :planCode     => :plan_code
                    ) 
      }      
    end
  end
    
  describe 'validate' do
    before { load_test_user_class }
    before { TestUser.stub(:connection).and_return mock(:columns => []) }

    let!(:test_user) {
      TestUser.new  
    }
    
    before {
      test_user.should_receive(:validate_subscription)
    }
    
    subject { test_user.valid? }

    it 'should call validate_subscription' do
      subject
    end
  end
  
  describe 'subscription' do
    let(:user)          { double("TestUser", 
      :customer_code  => "JOHN_DOE_CODE",
      :first_name     => "JOHN",
      :last_name      => "DOE"    
    )}

    let!(:subscription) { # use ! to set it now!
      CheddargetterClientRails::Subscription.new
    }

    before {
      CheddargetterClientRails::Subscription.stub(:new).and_return subscription
      user.should_receive(:subscription).at_least(1).times.and_return(subscription)
    }    
    
    context 'when not yet set' do
      subject { user.subscription }
      it { should eq(subscription) }    
    end
    
    context 'when already set' do
      before {
        subscription = user.subscription
        subscription.firstName = "First"
      }
      
      subject { user.subscription.firstName }
      it { should eq("First") }
    end
  end
  
  describe 'validate_subscription' do
    before { load_test_user_class }
    before { TestUser.stub(:connection).and_return mock(:columns => []) }

    let!(:user) {
      TestUser.new  
    }

    let(:subscription) {
      user.subscription
    }
    
    subject { user.validate_subscription }
    
    context 'subscription is valid' do
      before {
        user.should_receive(:skip_cheddargetter).and_return false
        user.should_receive(:new_record?).and_return true
        subscription.should_receive(:valid?).and_return true         
      }
      
      it "should not add errors" do
        subject
        (user.errors.length < 1).should be_true
      end
    end
  
    context 'when subscription is invalid' do
      before {
        user.should_receive(:skip_cheddargetter).and_return false
        user.should_receive(:new_record?).and_return true
        subscription.should_receive(:valid?).and_return false        
      }

      it "should add errors" do
        subject
        (user.errors.length < 1).should be_false
      end
    end
  end
end