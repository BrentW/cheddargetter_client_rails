module ActionController::RecordIdentifier
    def dom_class(record_or_class, prefix = nil)
      singular = ActiveModel::Naming.singular(record_or_class)
      prefix ? "#{prefix}#{JOIN}#{singular}" : singular
    end
end