# frozen_string_literal: true

require "active_model"
require "active_support/core_ext/string/inflections"
require "validation_kit/version"
require "validation_kit/country_option"

module ValidationKit
  VALIDATORS = {} # rubocop:disable Style/MutableConstant -- filled below, then frozen

  # Lets `validates :email, email: true` (and phone:, postal_code:,
  # mixed_case:) find this gem's validators. Rails resolves those keys with
  # const_get on the model, and Ruby only calls const_missing once normal
  # lookup -- including autoloading an app's own app/validators/*.rb -- has
  # failed, so an app's validator of the same name always wins.
  module ValidatorLookup
    def const_missing(name)
      VALIDATORS.fetch(name) { super }
    end
  end
end

lib_path = File.dirname(__FILE__)
Dir[File.join(lib_path, "**", "*_validator.rb")].each do |path|
  require path
  name = File.basename(path, ".rb").camelize
  ValidationKit::VALIDATORS[name.to_sym] = ValidationKit.const_get(name)
end
ValidationKit::VALIDATORS.freeze

ActiveModel::Validations::ClassMethods.include(ValidationKit::ValidatorLookup)

# Put the bundled translations first in the load path so an app's own
# locale files (which Rails appends later) can override them.
I18n.load_path.unshift(*Dir[File.join(lib_path, "validation_kit", "**", "locales", "*.yml")])
