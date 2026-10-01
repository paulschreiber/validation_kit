# frozen_string_literal: true

require "test_helper"

# Values that aren't strings (e.g. a ZIP code stored in an integer column)
# used to raise NoMethodError or TypeError instead of validating.
class NonStringValuesTest < Minitest::Test
  class Contact
    include ActiveModel::Validations

    attr_accessor :postcode, :phone, :email

    validates :postcode, postal_code: { country: "US", set: true }
    validates :phone, phone: { country: "US", set: true }
    validates :email, email: true
  end

  def contact(postcode: "10001", phone: "2125551234", email: "a@example.com")
    contact = Contact.new
    contact.postcode = postcode
    contact.phone = phone
    contact.email = email
    contact
  end

  def test_validates_and_formats_integers
    record = contact(postcode: 10_001, phone: 2_125_551_234)

    assert_predicate record, :valid?
    assert_equal "10001", record.postcode
    assert_equal "(212) 555-1234", record.phone
  end

  def test_rejects_invalid_integers
    record = contact(postcode: 1234, phone: 123, email: 12_345)

    refute_predicate record, :valid?
    assert_equal %i[email phone postcode], record.errors.attribute_names.sort
  end
end
