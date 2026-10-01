# frozen_string_literal: true

require "test_helper"

# Country codes used to be matched exactly, so "us" or :US silently skipped
# validation and let anything through.
class CountryCodeTest < Minitest::Test
  class Address
    include ActiveModel::Validations

    attr_accessor :country, :postcode, :phone

    validates :postcode, postal_code: { set: true }
    validates :phone, phone: { set: true }
  end

  COUNTRY_CODES = ["US", "us", :US, :us, " US "].freeze

  def address(country, postcode:, phone:)
    address = Address.new
    address.country = country
    address.postcode = postcode
    address.phone = phone
    address
  end

  def test_validates_with_any_case_or_type_of_country_code
    COUNTRY_CODES.each do |country|
      record = address(country, postcode: "nope", phone: "nope")
      record.valid?

      assert_equal %i[phone postcode], record.errors.attribute_names.sort, country.inspect
    end
  end

  def test_formats_with_any_case_or_type_of_country_code
    COUNTRY_CODES.each do |country|
      record = address(country, postcode: "100011234", phone: "2125551234")
      record.valid?

      assert_equal ["10001-1234", "(212) 555-1234"], [record.postcode, record.phone], country.inspect
    end
  end

  def test_public_helpers_accept_lowercase_codes
    phone = ValidationKit::PhoneValidator.new(attributes: [:phone])
    postal = ValidationKit::PostalCodeValidator.new(attributes: [:postcode])

    assert_equal phone.regex_for_country("US"), phone.regex_for_country("us")
    assert_equal postal.postal_code_regex_for_country("CA"), postal.postal_code_regex_for_country(:ca)
  end

  def test_unknown_countries_are_still_skipped
    assert_predicate address("ZZ", postcode: "nope", phone: "nope"), :valid?
  end
end
