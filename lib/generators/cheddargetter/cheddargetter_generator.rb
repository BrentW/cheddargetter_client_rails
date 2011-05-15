class CheddargetterGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)

  def generate_initializer
    copy_file "cheddargetter_client.rb", "config/initializers/cheddargetter_client.rb"
  end
  
  def generate_config
    copy_file "cheddargetter.yml", "config/cheddargetter.yml"
  end
end
