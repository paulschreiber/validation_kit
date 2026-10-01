# frozen_string_literal: true

require "test_helper"

class EmailValidatorTest < Minitest::Test
  class Contact
    include ActiveModel::Validations

    attr_accessor :email

    validates :email, email: true

    def initialize(email)
      @email = email
    end
  end

  VALID = [
    "a@example.com",
    "first.last+tag@sub.example.co.uk",
    "o'brien@example.com",
    '"john..doe"@example.com',
    "x@xn--bcher-kva.example",
    "user@[192.168.0.1]",
    "user@[IPv6:2001:db8::1]"
  ].freeze

  INVALID = [
    "",
    "plainaddress",
    "a@b",
    "a@@example.com",
    "a@-example.com",
    "a@example..com",
    ".a@example.com",
    "a@example.com\nfoo",
    "junk\na@example.com"
  ].freeze

  def valid?(email)
    Contact.new(email).valid?
  end

  def test_accepts_valid_addresses
    VALID.each { |email| assert valid?(email), "expected #{email.inspect} to be valid" }
  end

  def test_rejects_invalid_addresses
    INVALID.each { |email| refute valid?(email), "expected #{email.inspect} to be invalid" }
  end

  def test_rejects_nil
    refute valid?(nil)
  end

  # Each of these used to backtrack exponentially (or run for seconds) before
  # failing to match.
  def test_rejects_backtracking_inputs_quickly
    [
      "a@#{"a." * 30}!",
      "a@#{"a." * 1000}!",
      "a@#{"a-" * 1000}!",
      "#{"a." * 1000}@example.com!",
      "a@#{"a" * 10_000}.com!",
      "#{"a" * 10_000}@example.com"
    ].each do |email|
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      refute valid?(email)
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started

      assert_operator elapsed, :<, 0.5, "#{email[0, 20].inspect}... took #{elapsed.round(2)}s"
    end
  end
end
