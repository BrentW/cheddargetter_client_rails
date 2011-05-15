require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "RecordIdentifier" do
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

  describe 'dom_class(record)' do
    subject { ActionController::RecordIdentifier.dom_class(value) }
    
    context 'called with class' do
      context 'called with a CheddargetterClientRails::Subscription class' do
        let(:value) { CheddargetterClientRails::Subscription }
        it { should eq("subscription") }
      end
    
      context 'called with other classes' do
        let(:value) { TestUser }
        it { should eq("test_user") }        
      end
    end
    
    context 'called with object' do
      context 'called with a CheddargetterClientRails::Subscription class' do
        let(:value) { CheddargetterClientRails::Subscription.new }
        it { should eq("subscription") }
      end
    
      context 'called with other classes' do
        let(:value) { TestUser.new }
        it { should eq("test_user") }        
      end      
    end
  end
end