# validation_kit

ActiveModel validators for email addresses, phone numbers, postal codes, and
mixed-case text.

## Installation

Add the gem to your Gemfile:

```ruby
gem "validation_kit"
```

The validators are available in any class that includes
`ActiveModel::Validations`, including ActiveRecord models. If your app defines
its own validator with the same name (e.g. `app/validators/email_validator.rb`),
yours is used instead.

## Email

Validates that an attribute is an email address.

```ruby
class Person < ActiveRecord::Base
  validates :email, email: true
end

Person.new(email: "Bob").valid?            # => false
Person.new(email: "joe@foobar.com").valid? # => true
```

## Mixed case

Validates that a string isn't all capitals or all lowercase. Values with fewer
than three letters that have a case are skipped, so initials, digits, and
scripts without case (e.g. Chinese) never fail.

```ruby
class Person < ActiveRecord::Base
  validates :first_name, mixed_case: true
end

Person.new(first_name: "BOB").valid? # => false, "First name cannot be in all caps"
Person.new(first_name: "bob").valid? # => false, "First name cannot be in all lowercase"
Person.new(first_name: "Bob").valid? # => true
```

| Option            | Description                                                                                         |
| ----------------- | --------------------------------------------------------------------------------------------------- |
| `attribute_name:` | Name to use in the message. Defaults to the translated attribute name, then the humanized one.      |
| `all_caps:`       | Custom message for all-caps values.                                                                 |
| `all_lowercase:`  | Custom message for all-lowercase values.                                                            |

## Phone

Strict validation for phone numbers in the United States (`US`), Canada
(`CA`), and Australia (`AU`).

```ruby
class Person < ActiveRecord::Base
  validates :phone, phone: { country: "US", set: true }, allow_blank: true
end
```

| Option      | Description                                                                                                                        |
| ----------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| `country:`  | See [Specifying the country](#specifying-the-country).                                                                             |
| `set:`      | Reformat the stored value: `"1-212-555-1234 x5"` becomes `"(212) 555-1234 x5"`, `"0298765432"` becomes `"(02) 9876 5432"`.        |
| `area_key:` | For Australian landlines entered without an area code, the state whose area code to add (`"VIC"`, `"QLD"`, …; default NSW/ACT, `02`). |

## Postal code

Strict validation for postal and ZIP codes in the United States (`US`), Canada
(`CA`), the United Kingdom (`UK` or `GB`), Australia (`AU`), and New Zealand
(`NZ`).

```ruby
class Person < ActiveRecord::Base
  validates :postal_code, postal_code: { country: "CA", set: true }, allow_blank: true
end
```

| Option     | Description                                                                                                          |
| ---------- | -------------------------------------------------------------------------------------------------------------------- |
| `country:` | See [Specifying the country](#specifying-the-country).                                                               |
| `set:`     | Reformat the stored value: Canadian and UK codes get a space (`K1A 0B1`, `SW1A 1AA`), US ZIP+4 a hyphen (`10001-1234`). |

## Specifying the country

The phone and postal code validators need a country. Country codes are
case-insensitive (`"CA"`, `"ca"`, or `:CA`), and validation is skipped when the
country isn't supported.

```ruby
# A fixed country code
validates :phone, phone: { country: "CA" }

# The name of a method on your model that returns the country code
validates :phone, phone: { country: :billing_country }

# Neither: the validator calls your model's country method
validates :phone, phone: true
```

## Error messages

Errors are added with standard types, so the usual ActiveModel tools work:

```ruby
person.errors.added?(:email, :invalid)        # email, phone, postal code
person.errors.added?(:first_name, :all_caps)  # mixed case (also :all_lowercase)
```

Pass `message:` (or `all_caps:` / `all_lowercase:` for mixed case) for a custom
message, or translate it like any other Rails validation error:

```yaml
en:
  activerecord:
    errors:
      models:
        person:
          attributes:
            email:
              invalid: "Enter your email address"
            first_name:
              all_caps: "Your first name cannot be in all caps"
```

Use `activemodel` instead of `activerecord` for classes that aren't
ActiveRecord models. The gem includes English and French messages for the
mixed case errors.

## Credits

- Email, mixed case, and postal code validators by Paul Schreiber.
- Phone validator written by Kristina Lim
  ([i-think.com.ph](http://i-think.com.ph/kristina/)) for Syndeo Media, with US
  and Canada support and extensions added by Paul Schreiber. It is named after,
  and was originally built on, Jerrod Blavos's
  [validates_as_phone](http://code.google.com/p/validates-as-phone/) plugin.
- Gem co-authored by Wes Morgan.

## License

Released under the MIT License. See [LICENSE](LICENSE).
