# frozen_string_literal: true

require "test_helper"

class ErrorTypesTest < Minitest::Test
  class Contact
    include ActiveModel::Validations

    attr_accessor :email, :phone, :postcode, :name

    validates :email, email: true
    validates :phone, phone: { country: "US" }
    validates :postcode, postal_code: { country: "US" }
    validates :name, mixed_case: true
  end

  # Uses the activerecord scope, like an ActiveRecord model.
  class Record < Contact
    def self.i18n_scope = :activerecord
  end

  def invalid(klass = Contact)
    contact = klass.new
    contact.email = "not an email"
    contact.phone = "123"
    contact.postcode = "1234"
    contact.name = "JANE"
    contact.valid?
    contact.errors
  end

  def test_adds_errors_by_type
    errors = invalid

    %i[email phone postcode].each { |attribute| assert errors.added?(attribute, :invalid), "#{attribute} not :invalid" }
    assert errors.added?(:name, :all_caps, item: "Name")
    assert_equal [{ error: :invalid }], errors.details[:email]
  end

  def test_uses_the_default_messages_for_plain_active_model_models
    errors = invalid

    assert_equal ["is invalid"], errors[:email]
    assert_equal ["Name cannot be in all caps"], errors[:name]
  end

  def test_uses_model_specific_translations_in_the_models_scope
    attributes = { email: { invalid: "Enter your email address" }, name: { all_caps: "Please don't shout" } }
    models = { "error_types_test/record": { attributes: } }
    I18n.backend.store_translations(:en, activerecord: { errors: { models: } })
    errors = invalid(Record)

    assert_equal ["Enter your email address"], errors[:email]
    assert_equal ["Please don't shout"], errors[:name]
  ensure
    I18n.reload!
  end

  def test_uses_the_message_options
    klass = Class.new(Contact) do
      def self.name = "Custom"
      clear_validators!
      validates :email, email: { message: "bad email" }
      validates :name, mixed_case: { all_caps: "too loud" }
    end
    errors = invalid(klass)

    assert_equal ["bad email"], errors[:email]
    assert_equal ["too loud"], errors[:name]
  end
end
