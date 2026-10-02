# frozen_string_literal: true

module ValidationKit
  # The country: option shared by the phone and postal code validators.
  module CountryOption
    private

    # The country code to validate against, or nil to skip validation:
    # - a String is the code itself ("CA")
    # - a Symbol is the name of a method on the record that returns the code
    #   (:billing_country); if there's no such method, a two-letter symbol is
    #   the code itself (:CA), and anything else is a mistake, so it raises
    #   rather than silently skipping validation
    # - without the option, the record's country method, if it has one
    def country_for(record)
      option = options[:country]

      case option
      when String
        option
      when Symbol
        if record.respond_to?(option)
          record.public_send(option)
        elsif option.match?(/\A[a-z]{2}\z/i)
          option
        else
          raise ArgumentError, "country: #{option.inspect} is neither a public method on " \
                               "#{record.class.name || record.class.inspect} nor a two-letter country code"
        end
      else
        record.country if record.respond_to?(:country)
      end
    end
  end
end
