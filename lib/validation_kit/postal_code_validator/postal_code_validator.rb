# frozen_string_literal: true

module ValidationKit
  class PostalCodeValidator < ActiveModel::EachValidator
    def postal_code_regex_for_country(country_code)
      if country_code.blank?
        nil
      elsif %w[AU NZ].include?(country_code)
        /\A\d{4}\z/
      elsif ["US"].include?(country_code)
        /\A\d{5}(?:-?\d{4})?\z/
      elsif ["CA"].include?(country_code)
        /\A[ABCEGHJKLMNPRSTVXY]\d[ABCEGHJKLMNPRSTWVXYZ] ?\d[ABCEGHJKLMNPRSTWVXYZ]\d\z/
      end
    end

    def disallowed_characters_for_country(country_code)
      if country_code.blank?
        nil
      elsif %w[US AU NZ].include?(country_code)
        /[^0-9]/
      elsif %w[CA UK].include?(country_code)
        /[^0-9A-Z]/
      end
    end

    def validate_each(record, attribute, value)
      country = if options[:country].is_a?(String)
                  options[:country]
                elsif options[:country].is_a?(Symbol) && record.respond_to?(options[:country])
                  record.send(options[:country])
                elsif record.respond_to?(:country)
                  record.send(:country)
                else
                  false
                end

      return unless country

      current_regex = postal_code_regex_for_country(country)
      return unless current_regex

      disallowed_characters = disallowed_characters_for_country(country)

      new_value = value.to_s.upcase.gsub(disallowed_characters, "")

      # allow_blank/allow_nil are handled by ActiveModel on the original value,
      # so input that only becomes blank once cleaned up (e.g. "n/a") is invalid.
      if current_regex.match?(new_value)
        if options[:set]
          record.send("#{attribute}=",
                      format_as_postal_code(new_value, country, disallowed_characters))
        end
      else
        record.errors.add(attribute, :invalid, message: options[:message])
      end
    end

    def format_as_postal_code(arg, country_code, disallowed_characters)
      return nil if arg.blank? || country_code.blank? || !postal_code_regex_for_country(country_code)

      postal_code = arg.to_s.gsub(disallowed_characters, "")

      if ["US"].include?(country_code)
        digit_count = postal_code.length
        if digit_count == 5
          postal_code
        elsif digit_count == 9
          format("%s-%s", postal_code[0..4], postal_code[5..8])
        end

      elsif %w[AU NZ].include?(country_code)
        postal_code

      elsif ["CA"].include?(country_code)
        fsa = postal_code[0..2]
        lda = postal_code[3..5]

        postal_code = format("%s %s", fsa, lda)
        postal_code.upcase
      end
    end
  end
end
