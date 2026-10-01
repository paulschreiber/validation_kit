# frozen_string_literal: true

module ValidationKit
  class MixedCaseValidator < ActiveModel::EachValidator
    # Error types, also used as the I18n keys and option names for custom messages.
    ALL_CAPS = :all_caps
    ALL_LOWERCASE = :all_lowercase

    def validate_each(record, attribute, value)
      return if value.nil?

      # Only letters that have a case count, so digits, punctuation, and
      # scripts without case (e.g. Chinese) never trigger an error.
      upper = value.to_s.scan(/\p{Lu}/).size
      lower = value.to_s.scan(/\p{Ll}/).size
      return if upper + lower < 3 # skip very short words

      error = if lower.zero?
                ALL_CAPS
              elsif upper.zero?
                ALL_LOWERCASE
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
