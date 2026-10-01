# frozen_string_literal: true

require "test_helper"

class AllowBlankTest < Minitest::Test
  class Contact
    include ActiveModel::Validations

    attr_accessor :phone, :postcode

    validates :phone, phone: { country: "US", set: true }, allow_blank: true
    validates :postcode, postal_code: { country: "US", set: true }, allow_blank: true
  end

  def validate(phone:, postcode:)
    contact = Contact.new
    contact.phone = phone
    contact.postcode = postcode
    [contact.valid?, contact.phone, contact.postcode]
  end

  def test_allows_blank_and_nil_values
    assert_equal [true, "", ""], validate(phone: "", postcode: "")
    assert_equal [true, nil, nil], validate(phone: nil, postcode: nil)
  end

  # These used to pass (the blank check ran on the digits-only copy) and get
  # replaced with "" or nil.
  def test_rejects_values_that_are_only_blank_once_cleaned_up_and_keeps_them
    assert_equal [false, "call me", "n/a"], validate(phone: "call me", postcode: "n/a")
  end
end
