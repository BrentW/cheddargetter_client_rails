require File.expand_path(File.dirname(__FILE__) + '/spec_helper')



describe "CheddargetterClientRails" do
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
  
  before { ActiveRecord::Base.stub(:connection).and_return mock(:columns => []) }
  
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
    subject { user_class.respond_to?(:has_subscription) }
    
    it { should be_true }
  end
  
  describe 'has_subscription' do
    context 'argument errors' do
      context 'without customer code column' do
        subject {
          class NoCustomerCodeUser < ActiveRecord::Base
            has_subscription
          end
          NoCustomerCodeUser.stub(:connection).and_return mock(:columns => [])
          
        }
      
        specify { lambda { subject }.should raise_error(ArgumentError) }
      end 
      
      context 'when record does not responsd to customer_code_column' do
        subject {
          class NoCustomerCodeUser < ActiveRecord::Base
            has_subscription :id
          end
        }
        specify { lambda { subject }.should raise_error }
      end
    end
    
    context 'setting default values' do
      subject { 
        class DefaultValuesUser < ActiveRecord::Base
          attr_accessor :id, :email, :first_name, :last_name, :plan_code
          
          has_subscription
        end
      }
      
      specify { lambda { subject }.should_not raise_error }
      specify { 
        subject;
        DefaultValuesUser.shared_columns.should eq({
          :email => :email, 
          :firstName => :first_name, 
          :lastName => :last_name, 
          :planCode => :plan_code
        })
      }
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
                      :planCode     => :plan_code,
                      :email        => :email
                    ) 
      }      
    end
  end
    
  describe 'validate' do
    let!(:test_user) {
      TestUser.new  
    }
    
    subject { test_user.valid? }

    it 'should call validate_subscription' do
      test_user.should_receive(:validate_subscription)
      subject
    end
    
    it 'should call supplement_subscription_fields' do
      test_user.should_receive(:supplement_subscription_fields)
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
  
  describe 'responds_to_customer_code_column?' do
    context 'when columns include message' do
      before {
        class MessageInColumns < ActiveRecord::Base          
          def self.column_names
            ['customer_code']
          end
          
          has_subscription :customerCode => :customer_code
        end                    
      }
      
      let(:record_class) {
        MessageInColumns
      }

      before { record_class.stub(:connection).and_return mock(:columns => [])}      
      
      subject { record_class.responds_to_customer_code_column? }
      it { should be_true }
    end
    
    context 'when instance methods includes message' do
      before {
        class MessageInMethods < ActiveRecord::Base          
          
          def self.column_names
            []
          end

          def customer_code
            'TEST_CODE'
          end
          
          p 'Make not that if method and not column, then it must be declared before has_subscription'
                    
          has_subscription :customerCode => :customer_code
        end        
      }
      
      let(:record_class) {
        MessageInMethods
      }
  
      before { record_class.stub(:connection).and_return mock(:columns => [])}      
  
      subject { record_class.responds_to_customer_code_column? }      
      it { should be_true }
    end
    
    context 'when instance does not respond to message' do
      subject {
        class MessageMissing < ActiveRecord::Base   
          def self.column_names
            []
          end
          
          has_subscription :customer_code       
        end           
      }

      specify { lambda { subject }.should raise_error }
    end
  end
  
  describe 'supplement_subscription_fields' do
    let!(:user) {
      TestUser.new  
    }
    
    before { user.class.stub(:shared_columns).and_return({
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
    
    context 'when planCode is a string' do
      let!(:user) {
        TestUser.new  
      }

      before { user.class.stub(:shared_columns).and_return({
                                                  :planCode     => "EVERYBODYS_PLAN"
                                                })
      }

      subject { user.supplement_subscription_fields }
      specify { 
        subject
        user.subscription.planCode.should == "EVERYBODYS_PLAN"
      }
    end
  end

  describe 'create_subscription' do
    let!(:user) {
      TestUser.new  
    }
    
    subject { user.create_subscription }
    
    context 'when skipping cheddargetter' do
      before { user.customer_code = 'TEST_CODE' }
      before { user.skip_cheddargetter = true }
      before { user.subscription.should_not_receive(:create) }
      it do subject end
    end
    
    context 'when not skipping cheddargetter' do
      before { user.customer_code = 'TEST_CODE' }      
      before { user.skip_cheddargetter = false }
      before { user.subscription.should_receive(:create) }
      it do subject end
    end
    
    context 'when subscription customer_code is not set' do
      before { user.customer_code = 'TEST_CODE' }
      it do subject; user.subscription.customerCode.should eq('TEST_CODE') end
    end
    
    context 'when user customer code column is not set' do
      specify { lambda { subject }.should raise_error }
    end
  end
  
  describe 'current_subscription' do
    let!(:user) {
      TestUser.new  
    }
    
    let(:subscription) { CheddargetterClientRails::Subscription.new() }
    before { CheddargetterClientRails::Subscription.stub(:get).and_return subscription }
    
    context 'when it does not exist' do
      before { user.stub(:customer_code_column_value).and_return nil }
      subject { user.current_subscription }
      it { should be_nil }
    end    

    context 'when it does exist' do
      before { user.stub(:customer_code_column_value).and_return 'CUSTOMER_CODE' }
      context 'when it has not been accessed' do
        subject { user.current_subscription }
        it { should eq(subscription) }        
      end

      context 'when it has been accesssed' do
        before { user.current_subscription.firstName = 'First' }
        subject { user.current_subscription.firstName }
        it { should eq("First") }
      end    
    end
  end
  
  describe 'destroy_subscription' do
    let!(:user) {
      TestUser.new(:customer_code => 'CUSTOMER_CODE')  
    }
    
    let(:subscription) { CheddargetterClientRails::Subscription.new }    
    before { CheddargetterClientRails::Subscription.stub(:get).and_return subscription }
    before { subscription.should_receive(:destroy) }
    
    subject { user.destroy_subscription }
    it { subject }
  end
  
  describe 'build_subscription' do
    let!(:current_subscription) { 
      CheddargetterClientRails::Subscription.new({:firstName => "First", :lastName => "Last"}) 
    }    
        
    let(:subscription_params) {
      {:lastName => 'NewLast'}
    }
        
    subject { user.build_subscription(subscription_params) }
        
    context 'when current subscription' do
      before { user.stub(:current_subscription).and_return(current_subscription) }
      it 'should use data from current subscription' do
        subject
        user.subscription.firstName.should eq("First")
      end
      
      it 'should overwrite data from current_subscription' do
        subject
        user.subscription.lastName.should eq("NewLast")
      end
    end
    
    context 'when no current_subscription' do
      it 'should use a blank subscription object' do
        subject
        user.subscription.firstName.should be_nil
      end
      
      it 'should fill in new data' do
        subject
        user.subscription.lastName.should eq("NewLast")
      end
    end
  end
  
  describe 'customer_code_column_value' do
    subject { user.customer_code_column_value }
    
    context 'when customer_code_column is set and value is set' do
      before { user.customer_code = 'Customer Code' }
      it { should eq('Customer Code') }
    end
    
    context 'when the customer_code_column is set and it is an integeter' do
      before { user.customer_code = 12345 }
      it { should eq('12345') }
    end
    
    context 'when customer_code_column is not set' do
      before { user.class.stub(:customer_code_column).and_return nil }
      it { should be_nil }
    end
    
    context 'when value is not set' do
      it { should be_nil }
    end
  end
  
  describe 'save_subscription' do
    let!(:current_subscription) { 
      CheddargetterClientRails::Subscription.new({:firstName => "First", :lastName => "Last"}) 
    }    
        
    let!(:subscription_params) {
      {:lastName => 'NewLast'}
    }
    
    let!(:new_subscription) {
      CheddargetterClientRails::Subscription.new
    }
    
    subject { user.save_subscription(subscription_params) }
    
    before { CheddargetterClientRails::Subscription.stub(:new).and_return new_subscription }
    
    before { user.should_receive(:build_subscription) }
    before { user.subscription.should_receive(:save) }
    it do subject end
  end
end