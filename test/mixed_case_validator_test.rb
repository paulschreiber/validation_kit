# frozen_string_literal: true

require "test_helper"

class MixedCaseValidatorTest < Minitest::Test
  class Person
    include ActiveModel::Validations

    attr_accessor :first_name, :last_name

    validates :first_name, mixed_case: true
    validates :last_name, mixed_case: { attribute_name: "Surname", all_caps: "%{item} is all caps" } # rubocop:disable Style/FormatStringToken -- I18n interpolation, not a format string
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

  def test_uses_the_bundled_messages
    assert_equal ["cannot be in all caps"], errors_for(first_name: "JANE")[:first_name]
    assert_equal ["cannot be in all lowercase"], errors_for(first_name: "jane")[:first_name]
  end

  def test_full_messages_name_the_attribute_once
    assert_equal ["First name cannot be in all caps"], errors_for(first_name: "JANE").full_messages
  end

  def test_uses_the_attribute_name_option_for_item_in_a_custom_message
    assert_equal ["Surname is all caps"], errors_for(last_name: "SMITH")[:last_name]
  end

  # attribute_name: only fills in %{item}; full_messages use the attribute's
  # own (translated) name.
  def test_attribute_name_does_not_change_the_bundled_message
    assert_equal ["Last name cannot be in all lowercase"], errors_for(last_name: "smith").full_messages
  end

  def test_an_app_translation_can_still_use_item
    # Load the bundled translations first, or they'd be loaded lazily over this.
    I18n.backend.eager_load!
    I18n.backend.store_translations(:en, errors: { messages: { all_lowercase: "%{item} needs some capitals" } }) # rubocop:disable Style/FormatStringToken -- I18n interpolation

    assert_equal ["First name needs some capitals"], errors_for(first_name: "jane")[:first_name]
  ensure
    I18n.reload!
  end

  def test_prefers_a_translated_attribute_name
    I18n.backend.store_translations(
      :en, activemodel: { attributes: { "mixed_case_validator_test/person": { first_name: "Given name" } } }
    )

    assert_equal ["Given name cannot be in all caps"], errors_for(first_name: "JANE").full_messages
  ensure
    I18n.reload!
  end

  def test_bundled_french_messages
    I18n.with_locale(:fr) do
      assert_equal ["ne peut pas être en majuscules"], errors_for(first_name: "JANE")[:first_name]
    end
  end

  def test_ignores_values_without_enough_cased_letters
    ["123", "4-5-6", "李小龙", "J. R."].each do |name|
      assert_empty errors_for(first_name: name)[:first_name], name
    end
  end

  def test_counts_accented_letters
    assert_equal ["cannot be in all caps"], errors_for(first_name: "ÉLO")[:first_name]
    assert_equal ["cannot be in all lowercase"], errors_for(first_name: "élo")[:first_name]
  end
end
