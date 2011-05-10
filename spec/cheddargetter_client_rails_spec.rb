require File.expand_path(File.dirname(__FILE__) + '/spec_helper')



describe "CheddargetterClientRails" do
  before {
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
  
  before { TestUser.stub(:connection).and_return mock(:columns => []) }
  
  let(:user_class) {
    TestUser
  }
  
  let(:user) {
    TestUser.new
  }
  
  describe 'module included?' do
    subject { CheddargetterClientRails }
    specify { lambda { subject }.should_not raise_error }
  end
  
  describe "inclusion of class methods" do
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
      
      context 'when record does not responsd to customer_code_column' do
        subject {
          class NoCustomerCodeUser < ActiveRecord::Base
            cheddargetter_billable_on :id
          end
        }
        specify { lambda { subject }.should raise_error }
      end
    end
    
    context 'setting customer_code_column' do
      subject { user_class.customer_code_column }
      it { should eq(:customer_code) }
    end
    
    context 'setting shared_columns' do
      subject { user_class.shared_columns }
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
  
  describe 'before_create' do
    let!(:test_user) {
      TestUser.new  
    }

    before  { test_user.should_receive :create_subscription }
    subject { test_user.run_callbacks(:save) }
    it do subject end
  end
  
  describe 'subscription' do
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
    let!(:user) {
      TestUser.new  
    }

    let(:subscription) {
      user.subscription
    }
    
    subject { user.validate_subscription }
    
    context 'with subscription' do
      context 'that is valid' do
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
  
      context 'that is invalid' do
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
      
      context 'with no subscription' do
        before {
          user.stub(:skip_cheddargetter).and_return false
          user.stub(:new_record?).and_return true
        }
        
        specify { subject; user.valid?.should be_false }
      end
      
      context 'when skip_cheddargetter returns true' do
        before {
          user.stub(:skip_cheddargetter).and_return true
          user.stub(:new_record?).and_return true
          subscription.stub(:valid?).and_return true          
        }

        specify { subject; user.valid?.should be_true }
      end
      
      context 'when record is not new' do
        before {
          user.stub(:skip_cheddargetter).and_return false
          user.stub(:new_record?).and_return false
          subscription.stub(:valid?).and_return false        
        }

        specify { subject; user.valid?.should be_true }                
      end
    end
  end
  
  describe 'supplement_subscription_fields' do
    let!(:user) {
      TestUser.new  
    }
    
    before { user.stub(:shared_columns).and_return({
                                                :firstName    => :first_name, 
                                                :lastName     => :last_name, 
                                                :ccFirstName  => :first_name, 
                                                :ccLastName   => :last_name, 
                                                :planCode     => :plan_code
                                              })
    }
                                            
    before {
      user.customer_code  = "FIRST_NAME" 
      user.first_name     = "First"
      user.last_name      = "Last"
      user.plan_code      = "TEST_PLAN"
    }
    
    subject { user.supplement_subscription_fields }
    specify { 
      subject
      user.subscription.firstName.should == "First"
      user.subscription.lastName.should == "Last"
      user.subscription.planCode.should == "TEST_PLAN"
    }
  end

  describe 'create_subscription' do
    let!(:user) {
      TestUser.new  
    }
    
    subject { user.create_subscription }
    
    context 'when skipping cheddargetter' do
      before { user.skip_cheddargetter = true }
      before { user.subscription.should_not_receive(:create) }
      it do subject end
    end
    
    context 'when not skipping cheddargetter' do
      before { user.skip_cheddargetter = false }
      before { user.subscription.should_receive(:create) }
      it do subject end
    end
  end
  
  describe 'current_subscription' do
    let!(:user) {
      TestUser.new  
    }
    
    let(:subscription) { CheddargetterClientRails::Subscription.new }    
    before { CheddargetterClientRails::Subscription.stub(:get).and_return subscription }
    
    context 'when it has not been accesssed' do
      subject { user.current_subscription }
      it { should eq(subscription) }
    end    

    context 'when it has been accesssed' do
      before { user.current_subscription.firstName = 'First' }
      subject { user.current_subscription.firstName }
      it { should eq("First")}
    end    
  end
  
  describe 'destroy_subscription' do
    let!(:user) {
      TestUser.new  
    }
    
    let(:subscription) { CheddargetterClientRails::Subscription.new }    
    before { CheddargetterClientRails::Subscription.stub(:get).and_return subscription }
    before { subscription.should_receive(:destroy) }
    
    subject { user.destroy_subscription }
    it { subject }
  end
end