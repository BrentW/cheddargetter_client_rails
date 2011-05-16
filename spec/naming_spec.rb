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
  
  describe 'singular' do
    subject { ActiveModel::Naming.singular(record_or_class) }
    
    context 'called with class' do
      let(:record_or_class) { CheddargetterClientRails::Subscription }
      it { should eq('subscription') }
    end
    
    context 'called with class' do
      let(:record_or_class) { CheddargetterClientRails::Subscription.new }
      it { should eq('subscription') }      
    end
    
    context 'with user model' do
      context 'called with class' do
        let(:record_or_class) { TestUser }
        it { should eq('test_user') }
      end

      context 'called with class' do
        let(:record_or_class) { TestUser.new }
        it { should eq('test_user') }      
      end
    end
  end
  
  describe 'plural' do
    subject { ActiveModel::Naming.plural(record_or_class) }
    
    context 'called with class' do
      let(:record_or_class) { CheddargetterClientRails::Subscription }
      it { should eq('subscriptions') }
    end
    
    context 'called with class' do
      let(:record_or_class) { CheddargetterClientRails::Subscription.new }
      it { should eq('subscriptions') }      
    end
    
    context 'with user model' do
      context 'called with class' do
        let(:record_or_class) { TestUser }
        it { should eq('test_users') }
      end

      context 'called with class' do
        let(:record_or_class) { TestUser.new }
        it { should eq('test_users') }      
      end
    end
  end
  
  
  
end