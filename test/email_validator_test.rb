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
  # failing to match. Timed against EMAIL_ADDRESS_RE itself, since the
  # validator's length limits would reject most of them before the regex runs.
  BACKTRACKING_INPUTS = [
    "a@#{"a." * 30}!",
    "a@#{"a." * 1000}!",
    "a@#{"a-" * 1000}!",
    "#{"a." * 1000}@example.com!",
    "a@#{"a" * 10_000}.com!",
    "#{"a" * 10_000}@example.com!",
    # Quote characters: the length checks used to be lookaheads that tried
    # every split of a quote between neighbouring characters (about a minute
    # for 57 characters of 'a"a"…@').
    "#{'a"' * 28}@",
    "#{'"a' * 120}@x.com!",
    "#{'a"' * 2000}@",
    "\"#{"\\a" * 5000}@x",
    # The remaining lookaheads: domain label length and IPv6 group counts.
    "a@[IPv6:#{"1:" * 6}#{"1" * 20_000}",
    "a@[IPv6:#{"1:" * 4}:#{"1" * 20_000}",
    "a@#{"#{"a" * 63}." * 300}!"
  ].freeze

  def test_the_regex_rejects_backtracking_inputs_quickly
    BACKTRACKING_INPUTS.each do |email|
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      refute_match ValidationKit::EmailValidator::EMAIL_ADDRESS_RE, email
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started

      assert_operator elapsed, :<, 0.5, "#{email[0, 20].inspect}... took #{elapsed.round(2)}s"
    end
  end

  def test_the_validator_rejects_backtracking_inputs
    BACKTRACKING_INPUTS.each { |email| refute valid?(email), email[0, 20] }
  end

  # RFC 5321: at most 64 characters before the @, and 254 in all.
  def test_enforces_the_local_part_length_limit
    assert valid?("#{"a" * 64}@example.com")
    refute valid?("#{"a" * 65}@example.com")
  end

  def test_enforces_the_total_length_limit
    local_part = "a" * 64

    # 64 + 1 + 189 = 254 characters, with every label at most 63
    assert valid?("#{local_part}@#{"b" * 63}.#{"c" * 63}.#{"d" * 57}.com")
    # one more character in the domain: 255
    refute valid?("#{local_part}@#{"b" * 63}.#{"c" * 63}.#{"d" * 58}.com")
  end

  def test_counts_quotes_toward_the_local_part_limit
    assert valid?(%("#{"a" * 62}"@example.com))
    refute valid?(%("#{"a" * 63}"@example.com))
  end

  def test_a_quoted_local_part_can_contain_an_at_sign
    assert valid?('"a@b"@example.com')
  end

  def test_rejects_non_ascii_letters_that_case_fold_to_ascii
    refute valid?("a@ſx.com")
    refute valid?("a@\u212Aelvin.com")
  end

  def test_valid_address_is_public
    assert ValidationKit::EmailValidator.valid_address?("a@example.com")
    refute ValidationKit::EmailValidator.valid_address?("#{"a" * 65}@example.com")
    refute ValidationKit::EmailValidator.valid_address?(nil)
  end
end
