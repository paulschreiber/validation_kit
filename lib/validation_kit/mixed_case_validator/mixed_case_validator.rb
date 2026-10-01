# frozen_string_literal: true

module ValidationKit
  class MixedCaseValidator < ActiveModel::EachValidator
    # Error types, also used as the I18n keys and option names for custom messages.
    ALL_CAPS = :all_caps
    ALL_LOWERCASE = :all_lowercase

    def validate_each(record, attribute, value)
      return if value.nil?
      return if value.gsub(/\W/, "").size < 3 # skip very short words

      error = nil

      if value.upcase == value
        error = ALL_CAPS
      elsif value.downcase == value
        error = ALL_LOWERCASE
      end

      return if error.nil?

      record.errors.add(attribute, error, item: item_name(record, attribute), message: options[error])
    end

    private

    # A translated attribute name wins, then the :attribute_name option, then
    # the humanized attribute name.
    def item_name(record, attribute)
      scope = [record.class.i18n_scope, :attributes, record.class.model_name.i18n_key]
      I18n.t(attribute, scope:, default: nil) ||
        options[:attribute_name] ||
        record.class.human_attribute_name(attribute)
    end
  end
end
