module ActionController::RecordIdentifier
    def dom_class(record_or_class, prefix = nil)
      singular = ActiveModel::Naming.singular(record_or_class)
      value = prefix ? "#{prefix}#{JOIN}#{singular}" : singular
      value == "cheddargetter_client_rails_subscription" ? "subscription" : value
    end
end