# frozen_string_literal: true

module ValidationKit
  class PhoneValidator < ActiveModel::EachValidator
    def regex_for_country(country_code)
      if country_code.blank?
        nil
      elsif ["AU"].include?(country_code)
        /(^(1300|1800|1900|1902)\d{6}$)|(^(0?[12378])?[1-9][0-9]{7}$)|(^13\d{4}$)|(^0?4\d{8}$)/
      elsif %w[US CA].include?(country_code)
        /^1?[2-9]\d{2}[2-9]\d{2}\d{4}/
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

      current_regex = regex_for_country(country)
      return unless current_regex

      new_value = value.to_s.gsub(/[^0-9]/, "")

      model_name = record.class.to_s

      message = I18n.t("activerecord.errors.models.#{model_name.underscore}.attributes.#{attribute}.invalid",
                       default: [:"activerecord.errors.models.#{model_name.underscore}.invalid",
                                 options[:message], :"activerecord.errors.messages.invalid"])

      if (options[:allow_blank] && new_value.blank?) || new_value =~ current_regex
        if options[:set]
          formatted_phone = format_as_phone(value, country, options[:area_key])
          if formatted_phone.nil?
            record.errors.add(attribute, message)
          else
            record.send("#{attribute}=", formatted_phone)
          end
        end
      else
        record.errors.add(attribute, message)
      end
    end

    def format_as_phone(arg, country_code = nil, area_key = nil)
      return nil if arg.blank? || country_code.blank? || !regex_for_country(country_code)

      number = arg.gsub(/[^0-9]/, "")

      if country_code == "AU"
        case number
        when /^(1300|1800|1900|1902)\d{6}$/
          number.insert(4, " ").insert(8, " ")
        when /^(0?[12378])?[1-9][0-9]{7}$/
          number.insert(0, area_code_for_key(area_key)) if /^[1-9][0-9]{7}$/.match?(number)
          number.insert(0, "0") if /^[12378][1-9][0-9]{7}$/.match?(number)

          number.insert(0, "(").insert(3, ") ").insert(9, " ")
        when /^13\d{4}$/
          number.insert(2, " ").insert(5, " ")
        when /^0?4\d{8}$/
          number.insert(0, "0") if /^4\d{8}$/.match?(number)

          number.insert(4, " ").insert(8, " ")
        else
          number
        end
      elsif %w[CA US].include?(country_code)
        # if it's too short
        return number if number.length < 10

        # strip off the leading 1 (country code); any digits beyond ten are an extension
        number = number[1..] if number.length > 10 && number.start_with?("1")

        area_code = number[0..2]
        exchange = number[3..5]
        sln = number[6..9]

        if number.length == 10
          extension = nil
        else
          # save everything after the SLN as extension
          sln_index = arg.index(sln)
          # if something went wrong, return nil so we can error out
          # i.e. 519 444 000 ext 123 would cause sln to be 0001, which is not found
          # in the original string
          return nil if sln_index.nil?

          extension = " %s" % arg[(sln_index + 4)..].strip
        end

        format("(%s) %s-%s%s", area_code, exchange, sln, extension)
      end
    end

    def area_code_for_key(key)
      case key
      when "VIC", "TAS" then "03"
      when "QLD" then "07"
      when "SA", "NT", "WA" then "08"
      else
        "02" # NSW, ACT, and the default
      end
    end
  end
end
