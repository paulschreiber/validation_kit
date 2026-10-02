# frozen_string_literal: true

module ValidationKit
  class PhoneValidator < ActiveModel::EachValidator
    # Digits right after a US/CA number with no marker in front of them (any
    # letter, as in x, ext or extension, or #, ＃ or №): a mistyped number like
    # 212-555-12345, not an extension. \p{Nd} also catches non-ASCII digits.
    UNMARKED_US_CA_EXTENSION = /\A[^[:alpha:]#＃№]*\p{Nd}/

    def regex_for_country(country_code)
      country_code = country_code.to_s.strip.upcase

      if country_code.blank?
        nil
      elsif country_code == "AU"
        /\A(?:(?:1300|1800|1900|1902)\d{6}|(?:0?[12378])?[1-9][0-9]{7}|13\d{4}|0?4\d{8})\z/
      elsif %w[US CA].include?(country_code)
        /\A1?[2-9]\d{2}[2-9]\d{2}\d{4}/
      end
    end

    def validate_each(record, attribute, value)
      country = if options[:country].is_a?(String)
                  options[:country]
                elsif options[:country].is_a?(Symbol) && record.respond_to?(options[:country])
                  record.public_send(options[:country])
                elsif record.respond_to?(:country)
                  record.country
                else
                  false
                end

      return unless country

      # accept "us", :US, " US " as well as "US"
      country = country.to_s.strip.upcase
      return if country.empty?

      current_regex = regex_for_country(country)
      return unless current_regex

      new_value = value.to_s.gsub(/[^0-9]/, "")

      # allow_blank/allow_nil are handled by ActiveModel on the original value,
      # so input that only becomes blank once cleaned up (e.g. "n/a") is invalid.
      valid = current_regex.match?(new_value)
      # The US/CA regex only checks the start of the digits; format_as_phone is
      # what rejects extra digits that aren't a marked extension.
      valid &&= !format_as_phone(value, country).nil? if %w[US CA].include?(country)

      if valid
        if options[:set]
          formatted_phone = format_as_phone(value, country, options[:area_key])
          if formatted_phone.nil?
            record.errors.add(attribute, :invalid, message: options[:message])
          else
            record.public_send("#{attribute}=", formatted_phone)
          end
        end
      else
        record.errors.add(attribute, :invalid, message: options[:message])
      end
    end

    def format_as_phone(arg, country_code = nil, area_key = nil)
      country_code = country_code.to_s.strip.upcase
      return nil if arg.blank? || country_code.blank? || !regex_for_country(country_code)

      arg = arg.to_s
      number = arg.gsub(/[^0-9]/, "")

      if country_code == "AU"
        case number
        when /\A(?:1300|1800|1900|1902)\d{6}\z/
          number.insert(4, " ").insert(8, " ")
        when /\A(?:0?[12378])?[1-9][0-9]{7}\z/
          number.insert(0, area_code_for_key(area_key)) if /\A[1-9][0-9]{7}\z/.match?(number)
          number.insert(0, "0") if /\A[12378][1-9][0-9]{7}\z/.match?(number)

          number.insert(0, "(").insert(3, ") ").insert(9, " ")
        when /\A13\d{4}\z/
          number.insert(2, " ").insert(5, " ")
        when /\A0?4\d{8}\z/
          number.insert(0, "0") if /\A4\d{8}\z/.match?(number)

          number.insert(4, " ").insert(8, " ")
        end
      elsif %w[CA US].include?(country_code)
        # if it's too short
        return nil if number.length < 10

        # strip off the leading 1 (country code); any digits beyond ten are an
        # extension, unless they're unmarked (UNMARKED_US_CA_EXTENSION)
        leading_one = number.length > 10 && number.start_with?("1")
        number = number[1..] if leading_one

        area_code = number[0..2]
        exchange = number[3..5]
        sln = number[6..9]

        # everything after the last digit of the number
        national = arg[/\A(?:\D*\d){#{leading_one ? 11 : 10}}/]
        rest = arg[national.length..]

        # if letters appear among the number's digits, the extension's digits
        # were counted as part of the number (e.g. 519 444 000 ext 123), so
        # return nil to error out
        return nil if number.length > 10 && national.sub(/\A\D*/, "").match?(/[[:alpha:]]/)

        # Text after the number with no digits in it (e.g. "(cell)") is dropped;
        # with digits, it's the extension, if they're marked as one.
        extension = nil
        if rest.match?(/\p{Nd}/)
          return nil if UNMARKED_US_CA_EXTENSION.match?(rest)

          # [[:space:]] also covers non-breaking spaces, which strip doesn't
          extension = " #{rest.strip.sub(/\A[[:space:],;]+/, "").sub(/[[:space:]]+\z/, "")}"
        end

        "(#{area_code}) #{exchange}-#{sln}#{extension}"
      end
    end

    # key is an AU state, in any case, as a string or symbol (like country
    # codes).
    def area_code_for_key(key)
      case key.to_s.strip.upcase
      when "VIC", "TAS" then "03"
      when "QLD" then "07"
      when "SA", "NT", "WA" then "08"
      else
        "02" # NSW, ACT, and the default
      end
    end
  end
end
