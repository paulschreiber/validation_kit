# frozen_string_literal: true

require "test_helper"

class PostalCodeValidatorTest < Minitest::Test
  class Address
    include ActiveModel::Validations

    attr_accessor :postcode, :country

    validates :postcode, postal_code: { set: true }
  end

  def validate(postcode, country)
    address = Address.new
    address.postcode = postcode
    address.country = country
    [address.valid?, address.postcode]
  end

  def test_accepts_and_formats_valid_postal_codes
    [
      ["US", "10001", "10001"],
      ["US", "10001-1234", "10001-1234"],
      ["US", "100011234", "10001-1234"],
      ["AU", "2000", "2000"],
      ["NZ", "6011", "6011"],
      ["CA", "k1a0b1", "K1A 0B1"],
      ["CA", "K1A 0B1", "K1A 0B1"]
    ].each do |country, postcode, formatted|
      assert_equal [true, formatted], validate(postcode, country), "#{country} #{postcode}"
    end
  end

  # These used to pass validation (the regexes were unanchored) and then be
  # set to nil because they couldn't be formatted.
  def test_rejects_postal_codes_with_the_wrong_length_and_keeps_the_value
    {
      "US" => %w[1234 123456 1234567 12345678 1234567890 123456789012],
      "AU" => %w[123 12345],
      "NZ" => %w[123 12345],
      "CA" => %w[K1A0B K1A0B1X XK1A0B1]
    }.each do |country, postcodes|
      postcodes.each do |postcode|
        assert_equal [false, postcode], validate(postcode, country), "#{country} #{postcode}"
      end
    end
  end

  def test_regex_for_country_accepts_formatted_and_unformatted_codes
    validator = ValidationKit::PostalCodeValidator.new(attributes: [:postcode])

    assert_match validator.postal_code_regex_for_country("US"), "10001-1234"
    assert_match validator.postal_code_regex_for_country("CA"), "K1A 0B1"
    refute_match validator.postal_code_regex_for_country("US"), "10001\n99999"
  end

  UK_COUNTRY_CODES = %w[UK GB].freeze

  def test_validates_and_formats_uk_postcodes
    [
      ["SW1A 1AA", "SW1A 1AA"],
      ["sw1a1aa", "SW1A 1AA"],
      ["M1 1AE", "M1 1AE"],
      ["B338TH", "B33 8TH"],
      ["CR2 6XH", "CR2 6XH"],
      ["DN55 1PT", "DN55 1PT"],
      ["EC1A 1BB", "EC1A 1BB"],
      ["GIR 0AA", "GIR 0AA"]
    ].each do |postcode, formatted|
      UK_COUNTRY_CODES.each do |country|
        assert_equal [true, formatted], validate(postcode, country), "#{country} #{postcode}"
      end
    end
  end

  def test_rejects_invalid_uk_postcodes
    ["SW1A 1A", "SW1A 1AAA", "12345", "1AA 1AA", "SW1A"].each do |postcode|
      assert_equal [false, postcode], validate(postcode, "UK"), postcode
    end
  end

  def test_validates_and_keeps_nz_postcodes_with_set
    assert_equal [true, "6011"], validate("6011", "NZ")
    assert_equal [false, "60111"], validate("60111", "NZ")
  end
end
