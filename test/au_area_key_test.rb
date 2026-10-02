# frozen_string_literal: true

require "test_helper"

# area_key: adds an Australian state's area code to a landline entered without
# one. Unknown keys used to silently get the NSW/ACT code (02).
class AuAreaKeyTest < Minitest::Test
  class Office
    include ActiveModel::Validations

    attr_accessor :phone

    validates :phone, phone: { country: "AU", set: true, area_key: :vic }
  end

  def validator
    ValidationKit::PhoneValidator.new(attributes: [:phone], country: "AU")
  end

  def test_each_state_gets_its_area_code
    { "NSW" => "02", "ACT" => "02", "VIC" => "03", "TAS" => "03",
      "QLD" => "07", "SA" => "08", "NT" => "08", "WA" => "08" }.each do |state, code|
      assert_equal "(#{code}) 9876 5432", validator.format_as_phone("9876 5432", "AU", state), state
    end
  end

  def test_no_key_means_nsw_and_act
    [nil, "", " "].each do |key|
      assert_equal "(02) 9876 5432", validator.format_as_phone("9876 5432", "AU", key), key.inspect
    end
  end

  def test_an_unknown_key_raises
    ["Victoria", "VCI", "03", 3, :queensland].each do |key|
      error = assert_raises(ArgumentError, key.inspect) { validator.format_as_phone("9876 5432", "AU", key) }
      assert_includes error.message, key.inspect
    end
  end

  # Whatever number is passed, so it can't depend on what a user typed.
  def test_an_unknown_key_raises_for_any_number
    ["03 9876 5432", "0412 345 678", "1300 123 456", ""].each do |number|
      assert_raises(ArgumentError, number) { validator.format_as_phone(number, "AU", "Victoria") }
    end
    assert_raises(ArgumentError) { validator.format_as_phone("212-555-1234", "US", "Victoria") }
  end

  def test_an_unknown_area_key_option_raises_when_the_model_is_defined
    error = assert_raises(ArgumentError) do
      Class.new do
        include ActiveModel::Validations

        attr_accessor :phone

        validates :phone, phone: { country: "AU", set: true, area_key: "Victoria" }
      end
    end
    assert_includes error.message, '"Victoria"'
  end

  def test_the_validator_adds_the_area_code_with_set
    office = Office.new
    office.phone = "9876 5432"

    assert_predicate office, :valid?
    assert_equal "(03) 9876 5432", office.phone
  end

  def test_the_validator_keeps_an_area_code_that_was_entered
    office = Office.new
    office.phone = "07 9876 5432"

    assert_predicate office, :valid?
    assert_equal "(07) 9876 5432", office.phone
  end
end
