module ActiveModel::Naming
  def self.singular(record_or_class)
    model_name_from_record_or_class(record_or_class).singular.gsub('cheddargetter_client_rails_', '')
  end
  
  def self.plural(record_or_class)
    model_name_from_record_or_class(record_or_class).plural.gsub('cheddargetter_client_rails_', '')
  end
end