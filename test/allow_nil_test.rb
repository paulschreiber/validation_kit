# frozen_string_literal: true

require "test_helper"

class AllowNilTest < Minitest::Test
  class Contact
    include ActiveModel::Validations

    attr_accessor :email, :phone, :postcode, :name

    validates :email, email: true, allow_nil: true
    validates :phone, phone: { country: "US", set: true }, allow_nil: true
    validates :postcode, postal_code: { country: "US", set: true }, allow_nil: true
    validates :name, mixed_case: true, allow_nil: true
  end

  def contact(value)
    contact = Contact.new
    %i[email phone postcode name].each { |attribute| contact.public_send("#{attribute}=", value) }
    contact
  end

  def test_skips_nil_values
    assert_predicate contact(nil), :valid?
  end

  def test_still_validates_blank_strings
    record = contact("")
    record.valid?

    assert_equal %i[email phone postcode], record.errors.attribute_names.sort
  end
end
