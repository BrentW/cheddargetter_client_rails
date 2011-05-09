require File.expand_path(File.dirname(__FILE__) + '/spec_helper')



describe "CheddargetterClientRails" do
  describe 'module included?' do
    subject { CheddargetterClientRails }
    specify { lambda { subject }.should_not raise_error }
  end
  
   describe "inclusion of class methods" do
    let(:user_class) { TestUser } 

    subject { user_class.respond_to?(:cheddargetter_billable_on) }
    
    it { should be_true }
  end
end
