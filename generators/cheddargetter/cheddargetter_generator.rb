class CheddargetterGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      m.directory 'config/initializers'

      m.template "cheddargetter_client.rb", "config/initializers/cheddargetter_client.rb"
      m.file "cheddargetter.yml", "config/cheddargetter.yml"
    end
  end