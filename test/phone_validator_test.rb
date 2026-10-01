# frozen_string_literal: true

require "test_helper"

class PhoneValidatorTest < Minitest::Test
  def validator
    ValidationKit::PhoneValidator.new(attributes: [:phone], country: "AU")
  end

  def test_au_regex_accepts_landlines_with_and_without_area_code
    regex = validator.regex_for_country("AU")

    assert_match regex, "0298765432"
    assert_match regex, "298765432"
    assert_match regex, "98765432"
  end

  def test_au_regex_does_not_treat_a_pipe_as_an_area_code_digit
    regex = validator.regex_for_country("AU")

    refute_match regex, "|98765432"
    refute_match regex, "0|98765432"
  end

  def test_formats_au_landlines
    assert_equal "(02) 9876 5432", validator.format_as_phone("02 9876 5432", "AU")
    assert_equal "(02) 9876 5432", validator.format_as_phone("2 9876 5432", "AU")
    assert_equal "(03) 9876 5432", validator.format_as_phone("9876 5432", "AU", "VIC")
  end

  def test_formats_us_numbers_with_a_leading_country_code_without_a_trailing_space
    us = ValidationKit::PhoneValidator.new(attributes: [:phone], country: "US")

    [
      ["212-555-1234", "(212) 555-1234"],
      ["1-212-555-1234", "(212) 555-1234"],
      ["+1 (212) 555-1234", "(212) 555-1234"],
      ["12125551234", "(212) 555-1234"],
      ["212-555-1234 x5", "(212) 555-1234 x5"],
      ["1-212-555-1234 ext. 99", "(212) 555-1234 ext. 99"]
    ].each do |input, formatted|
      assert_equal formatted, us.format_as_phone(input, "US"), input
    end
  end

  def test_takes_the_extension_from_after_the_number
    us = ValidationKit::PhoneValidator.new(attributes: [:phone], country: "US")

    [
      ["2223332223 ext 5", "(222) 333-2223 ext 5"],
      ["2125551212 x1212", "(212) 555-1212 x1212"],
      ["Tel: 212-555-1234 x5", "(212) 555-1234 x5"],
      ["1 222 333 2223 ext 5", "(222) 333-2223 ext 5"]
    ].each do |input, formatted|
      assert_equal formatted, us.format_as_phone(input, "US"), input
    end
  end

  def test_rejects_a_short_number_whose_extension_would_complete_it
    us = ValidationKit::PhoneValidator.new(attributes: [:phone], country: "US")

    assert_nil us.format_as_phone("519 444 000 ext 123", "US")
  end
end
