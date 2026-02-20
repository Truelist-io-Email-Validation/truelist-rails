# frozen_string_literal: true

class DeliverableValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    result = Truelist::Client.new.validate(value)

    allow_risky = if options.key?(:allow_risky)
                    options[:allow_risky]
                  else
                    Truelist.configuration.allow_risky
                  end

    # Fail open for transient errors (timeouts, 500s) so forms still work when API is down
    return if result.error?

    deliverable = result.state == 'valid' || (result.state == 'risky' && allow_risky) || result.unknown?

    return if deliverable

    message = options[:message] || :invalid_email
    record.errors.add(attribute, message)
  end
end
