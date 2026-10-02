# frozen_string_literal: true

module ValidationKit
  class EmailValidator < ActiveModel::EachValidator
    # RFC 5321's length limits: the whole address, and the part before the @.
    # They're checked in validate_each rather than as lookaheads at the start of
    # EMAIL_ADDRESS_RE, where they backtracked exponentially on input like
    # 'a"a"a"…@' (about a minute for 57 characters).
    MAX_LENGTH = 254
    MAX_LOCAL_PART_LENGTH = 64

    # The address syntax only; validate_each also applies the length limits.
    EMAIL_ADDRESS_RE = /\A(?:(?:[\x21\x23-\x27\x2A\x2B\x2D\x2F-\x39\x3D\x3F\x5E-\x7E]+)|(?:\x22(?:[\x01-\x08\x0B\x0C\x0E-\x1F\x21\x23-\x5B\x5D-\x7F]|(?:\x5C[\x00-\x7F]))*\x22))(?:\.(?:(?:[\x21\x23-\x27\x2A\x2B\x2D\x2F-\x39\x3D\x3F\x5E-\x7E]+)|(?:\x22(?:[\x01-\x08\x0B\x0C\x0E-\x1F\x21\x23-\x5B\x5D-\x7F]|(?:\x5C[\x00-\x7F]))*\x22)))*@(?:(?:(?!.*[^.]{64,})(?:(?:xn--)?[a-z0-9]+(?:-[a-z0-9]+)*\.){1,126}(?:(?:[a-z][a-z0-9]*)|(?:(?:xn--)[a-z0-9]+))(?:-[a-z0-9]+)*)|(?:\[(?:(?:IPv6:(?:(?:[a-f0-9]{1,4}(?::[a-f0-9]{1,4}){7})|(?:(?!(?:.*[a-f0-9][:\]]){7,})(?:[a-f0-9]{1,4}(?::[a-f0-9]{1,4}){0,5})?::(?:[a-f0-9]{1,4}(?::[a-f0-9]{1,4}){0,5})?)))|(?:(?:IPv6:(?:(?:[a-f0-9]{1,4}(?::[a-f0-9]{1,4}){5}:)|(?:(?!(?:.*[a-f0-9]:){5,})(?:[a-f0-9]{1,4}(?::[a-f0-9]{1,4}){0,3})?::(?:[a-f0-9]{1,4}(?::[a-f0-9]{1,4}){0,3}:)?)))?(?:(?:25[0-5])|(?:2[0-4][0-9])|(?:1[0-9]{2})|(?:[1-9]?[0-9]))(?:\.(?:(?:25[0-5])|(?:2[0-4][0-9])|(?:1[0-9]{2})|(?:[1-9]?[0-9]))){3}))\]))\z/i

    # Whether address is a valid email address: the syntax and the length
    # limits. For use outside a model; EMAIL_ADDRESS_RE alone skips the limits.
    def self.valid_address?(address)
      address = address.to_s
      # The syntax is ASCII-only, but the regex's /i matching would also let
      # Unicode case-folded letters (ſ, the Kelvin sign) through as s and k.
      return false unless address.ascii_only?
      return false if address.length > MAX_LENGTH

      # The domain can't contain an @, so the last one ends the local part.
      address.rpartition("@").first.length <= MAX_LOCAL_PART_LENGTH && EMAIL_ADDRESS_RE.match?(address)
    end

    def validate_each(record, attribute, value)
      return if self.class.valid_address?(value)

      record.errors.add(attribute, :invalid, message: options[:message])
    end
  end
end
