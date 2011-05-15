class CheddargetterGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      m.file "cheddargetter_client.rb", "config/initializers/cheddargetter_client.rb"
    end
    
    record do |m|
      m.file "cheddargetter.yml", "config/cheddargetter.yml"
    end
  end
end