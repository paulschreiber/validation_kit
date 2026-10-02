# frozen_string_literal: true

require "test_helper"

# A Symbol country: option used to be treated only as a method name, so
# `country: :CA` on a model without a CA method fell back to record.country, or
# skipped validation entirely.
class CountryOptionTest < Minitest::Test
  # No country method, so only the option can supply the country.
  class Contact
    include ActiveModel::Validations

    attr_accessor :phone, :postcode

    validates :phone, phone: { country: :CA }, allow_nil: true
    validates :postcode, postal_code: { country: :ca }, allow_nil: true
  end

  # Its own country method says US, but the option says CA.
  class Office < Contact
    def country = "US"
  end

  class Customer
    include ActiveModel::Validations

    attr_accessor :phone, :billing_country

    validates :phone, phone: { country: :billing_country }
  end

  def test_a_two_letter_symbol_is_a_country_code
    contact = Contact.new
    contact.phone = "nope"
    contact.postcode = "nope"

    refute_predicate contact, :valid?
    assert_equal %i[phone postcode], contact.errors.attribute_names.sort
  end

  def test_a_country_code_symbol_validates_for_that_country
    contact = Contact.new
    contact.phone = "604-555-1234"
    contact.postcode = "K1A 0B1"

    assert_predicate contact, :valid?
  end

  def test_a_country_code_symbol_wins_over_the_records_country_method
    office = Office.new
    office.postcode = "K1A 0B1" # a Canadian postal code, not a US ZIP code

    assert_predicate office, :valid?
  end

  def test_a_symbol_naming_a_method_still_calls_it
    customer = Customer.new
    customer.billing_country = "US"
    customer.phone = "nope"

    refute_predicate customer, :valid?

    customer.phone = "212-555-1234"

    assert_predicate customer, :valid?
  end

  def test_a_misspelled_method_name_raises_instead_of_skipping_validation
    klass = Class.new(Customer) do
      def self.name = "MisspelledCustomer"

      clear_validators!
      validates :phone, phone: { country: :billing_contry }
    end
    record = klass.new
    record.phone = "nope"

    error = assert_raises(ArgumentError) { record.valid? }
    assert_includes error.message, ":billing_contry"
    assert_includes error.message, "MisspelledCustomer"
  end

  def test_the_error_names_an_anonymous_model_class
    klass = Class.new do
      include ActiveModel::Validations

      attr_accessor :phone

      validates :phone, phone: { country: :billing_contry }
    end
    record = klass.new
    record.phone = "nope"

    error = assert_raises(ArgumentError) { record.valid? }
    assert_includes error.message, "#<Class:"
  end

  def test_an_unsupported_country_code_symbol_is_skipped_like_a_string
    klass = Class.new(Customer) do
      def self.name = "GermanCustomer"

      clear_validators!
      validates :phone, phone: { country: :DE }
    end
    record = klass.new
    record.phone = "nope"

    assert_predicate record, :valid?
  end
end
