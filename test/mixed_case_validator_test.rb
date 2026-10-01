# frozen_string_literal: true

require "test_helper"

class MixedCaseValidatorTest < Minitest::Test
  class Person
    include ActiveModel::Validations

    attr_accessor :first_name, :last_name

    validates :first_name, mixed_case: true
    validates :last_name, mixed_case: { attribute_name: "Surname" }
  end

  def errors_for(first_name: "Jane", last_name: "Smith")
    person = Person.new
    person.first_name = first_name
    person.last_name = last_name
    person.valid?
    person.errors
  end

  def test_accepts_mixed_case_and_short_values
    assert_empty errors_for(first_name: "Jane", last_name: "Al")
  end

  def test_uses_the_bundled_messages_with_a_humanized_attribute_name
    assert_equal ["First name cannot be in all caps"], errors_for(first_name: "JANE")[:first_name]
    assert_equal ["First name cannot be in all lowercase"], errors_for(first_name: "jane")[:first_name]
  end

  def test_uses_the_attribute_name_option
    assert_equal ["Surname cannot be in all caps"], errors_for(last_name: "SMITH")[:last_name]
  end

  def test_prefers_a_translated_attribute_name
    I18n.backend.store_translations(
      :en, activemodel: { attributes: { "mixed_case_validator_test/person": { first_name: "Given name" } } }
    )

    assert_equal ["Given name cannot be in all caps"], errors_for(first_name: "JANE")[:first_name]
  ensure
    I18n.reload!
  end

  def test_bundled_french_messages
    I18n.with_locale(:fr) do
      assert_equal ["First name ne peut pas être en majuscules"], errors_for(first_name: "JANE")[:first_name]
    end
  end

  def test_ignores_values_without_enough_cased_letters
    ["123", "4-5-6", "李小龙", "J. R."].each do |name|
      assert_empty errors_for(first_name: name)[:first_name], name
    end
  end

  def test_counts_accented_letters
    assert_equal ["First name cannot be in all caps"], errors_for(first_name: "ÉLO")[:first_name]
    assert_equal ["First name cannot be in all lowercase"], errors_for(first_name: "élo")[:first_name]
  end
end
