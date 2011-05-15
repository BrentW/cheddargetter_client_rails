cheddargetter_config = YAML.load_file(File.join(Rails.root, 'config', 'cheddargetter.yml'))[Rails.env]
CGClient = CheddarGetter::Client.new(
	:product_code => cheddargetter_config['product_code'],
	:username			=> cheddargetter_config['username'],
	:password			=> cheddargetter_config['password']
)