# frozen_string_literal: true

require "test_helper"

# Digits after a US/CA number are only an extension with a marker in front.
class PhoneExtensionTest < Minitest::Test
  class Contact
    include ActiveModel::Validations

    attr_accessor :phone, :formatted_phone

    validates :phone, phone: { country: "US" }, allow_nil: true
    validates :formatted_phone, phone: { country: "CA", set: true }, allow_nil: true
  end

  class CanadianContact
    include ActiveModel::Validations

    attr_accessor :phone

    validates :phone, phone: { country: "CA" }
  end

  def us
    ValidationKit::PhoneValidator.new(attributes: [:phone], country: "US")
  end

  def test_accepts_each_extension_marker
    [
      ["212-555-1234 #5", "(212) 555-1234 #5"],
      ["212-555-1234 extension 5", "(212) 555-1234 extension 5"],
      ["212-555-1234 X 5", "(212) 555-1234 X 5"],
      ["212-555-1234, ext 5", "(212) 555-1234 ext 5"],
      ["212-555-1234 x5.", "(212) 555-1234 x5."],
      ["212-555-1234 (x5)", "(212) 555-1234 (x5)"],
      ["212-555-1234 ext: 5", "(212) 555-1234 ext: 5"],
      ["212-555-1234 x. 5", "(212) 555-1234 x. 5"],
      ["212-555-1234 ext-5", "(212) 555-1234 ext-5"],
      ["212-555-1234 extn 5", "(212) 555-1234 extn 5"],
      ["212-555-1234\u00A0x5", "(212) 555-1234 x5"],
      ["212-555-1234 ＃5", "(212) 555-1234 ＃5"],
      ["212-555-1234 № 5", "(212) 555-1234 № 5"],
      ["212-555-1234 x５", "(212) 555-1234 x５"],
      ["212-555-1234 x5\0", "(212) 555-1234 x5"],
      ["1-212-555-1234 ext 5", "(212) 555-1234 ext 5"]
    ].each do |input, formatted|
      assert_equal formatted, us.format_as_phone(input, "US"), input
    end
  end

  def test_marked_extensions_are_valid
    ["212-555-1234 x5.", "212-555-1234 (x5)", "212-555-1234 ext: 5", "1-212-555-1234 ext 5",
     "212-555-1234 ＃5"].each do |input|
      contact = Contact.new
      contact.phone = input
      contact.formatted_phone = input

      assert_predicate contact, :valid?, input
    end
  end

  def test_rejects_digits_after_the_number_without_a_marker
    ["212-555-12345", "2125551234 1", "212-555-1234 55", "1-212-555-1234 5", "212-555-1234 -5", "212-555-1234 (5)",
     "212-555-1234\u00A05", "212-555-1234\t5", "212-555-1234\n5", "212-555-1234 ５", "212-555-1234 ٥",
     "212-555-1234 ５ x6"].each do |input|
      assert_nil us.format_as_phone(input, "US"), input
    end
  end

  def test_unmarked_digits_are_invalid_without_set
    contact = Contact.new
    contact.phone = "212-555-12345"

    refute_predicate contact, :valid?
    assert contact.errors.of_kind?(:phone, :invalid)
  end

  def test_letters_among_the_numbers_digits_are_invalid_without_set
    contact = Contact.new
    contact.phone = "519 444 000 ext 123"

    refute_predicate contact, :valid?
    assert contact.errors.of_kind?(:phone, :invalid)
  end

  def test_unmarked_digits_are_invalid_for_canada_without_set
    contact = CanadianContact.new
    contact.phone = "604-555-12345"

    refute_predicate contact, :valid?
    assert contact.errors.of_kind?(:phone, :invalid)
  end

  def test_unmarked_digits_are_invalid_with_set_and_left_unchanged
    contact = Contact.new
    contact.formatted_phone = "604-555-12345"

    refute_predicate contact, :valid?
    assert contact.errors.of_kind?(:formatted_phone, :invalid)
    assert_equal "604-555-12345", contact.formatted_phone
  end

  def test_marked_extensions_are_still_valid_with_or_without_set
    contact = Contact.new
    contact.phone = "212-555-1234 x5"
    contact.formatted_phone = "604-555-1234 ext 7"

    assert_predicate contact, :valid?
    assert_equal "(604) 555-1234 ext 7", contact.formatted_phone
  end
end
