# frozen_string_literal: true

require "active_model"
require "active_support/core_ext/string/inflections"
require "validation_kit/version"

lib_path = File.dirname(__FILE__)
validators = Dir[File.join(lib_path, "**", "*_validator.rb")]
validators.each do |v|
  require v
  validator_class = File.basename(v, ".rb").camelize
  validator = "ValidationKit::#{validator_class}".constantize
  ActiveModel::Validations.const_set(validator_class, validator)
end

# Put the bundled translations first in the load path so an app's own
# locale files (which Rails appends later) can override them.
I18n.load_path.unshift(*Dir[File.join(lib_path, "validation_kit", "**", "locales", "*.yml")])
