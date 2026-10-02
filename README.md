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

| Option            | Description                                                                                                                                                                              |
| ----------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `attribute_name:` | Name for `%{item}` in a custom message. Defaults to the translated attribute name, then the humanized one. It doesn’t change `full_messages`, which use the attribute’s translated name. |
| `all_caps:`       | Custom message for all-caps values.                                                                                                                                                      |
| `all_lowercase:`  | Custom message for all-lowercase values.                                                                                                                                                 |

## Phone

Strict validation for phone numbers in the United States (`US`), Canada
(`CA`), and Australia (`AU`).

```ruby
class Person < ActiveRecord::Base
  validates :phone, phone: { country: "US", set: true }, allow_blank: true
end
```

| Option      | Description                                                                                                                                       |
| ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| `country:`  | See [Specifying the country](#specifying-the-country).                                                                                            |
| `set:`      | Reformat the stored value: `"1-212-555-1234 x5"` becomes `"(212) 555-1234 x5"`, `"0298765432"` becomes `"(02) 9876 5432"`.                        |
| `area_key:` | For Australian landlines entered without an area code, the state whose area code to add (`"VIC"`, `:qld`, …, in any case; default NSW/ACT, `02`). |

A US or Canadian number may end with an extension, which needs a marker in
front of its digits: any letter (as in `x`, `ext` or `extension`), or `#`, `＃`
or `№` (`"212-555-1234 ext 5"`). Digits right after the number with no marker,
as in `"212-555-12345"`, make it invalid.

## Postal code

Strict validation for postal and ZIP codes in the United States (`US`), Canada
(`CA`), the United Kingdom (`UK` or `GB`), Australia (`AU`), and New Zealand
(`NZ`).

```ruby
class Person < ActiveRecord::Base
  validates :postal_code, postal_code: { country: "CA", set: true }, allow_blank: true
end
```

| Option     | Description                                                                                                             |
| ---------- | ----------------------------------------------------------------------------------------------------------------------- |
| `country:` | See [Specifying the country](#specifying-the-country).                                                                  |
| `set:`     | Reformat the stored value: Canadian and UK codes get a space (`K1A 0B1`, `SW1A 1AA`), US ZIP+4 a hyphen (`10001-1234`). |

## Specifying the country

The phone and postal code validators need a country. Country codes are
case-insensitive (`"CA"`, `"ca"`, or `:CA`), and validation is skipped when the
country isn't supported.

```ruby
# A fixed country code, as a string or a two-letter symbol
validates :phone, phone: { country: "CA" }
validates :phone, phone: { country: :ca }

# The name of a method on your model that returns the country code
validates :phone, phone: { country: :billing_country }

# Neither: the validator calls your model's country method
validates :phone, phone: true
```

A symbol is a method name if your model has that public method; otherwise a
two-letter symbol is a country code. Any other symbol (such as a misspelled
method name) raises `ArgumentError` when validating, rather than skipping
validation. Two things that check can't catch: a misspelled two-letter method
name is read as a country code (and skipped if that country isn't supported),
and with `allow_nil:` or `allow_blank:` it only runs once the attribute has a
value.

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
              invalid: "doesn’t look like an email address"
            first_name:
              all_caps: "can’t be all capitals"
```

Like Rails’ own messages, these leave out the attribute’s name, because
`full_messages` adds it: "First name can’t be all capitals". Use `activemodel`
instead of `activerecord` for classes that aren't ActiveRecord models. The gem includes English and French messages for the
mixed case errors.

## Translation keys

Each validator adds an error of the type below. Rails looks up its message in
this order, using the first key it finds. These are the keys for an
ActiveRecord model `Person`; use `activemodel` instead of `activerecord` for
other ActiveModel classes:

1. `activerecord.errors.models.person.attributes.<attribute>.<type>`
2. `activerecord.errors.models.person.<type>`
3. `activerecord.errors.messages.<type>`
4. `errors.attributes.<attribute>.<type>`
5. `errors.messages.<type>`

A `message:` option (or `all_caps:` / `all_lowercase:`) skips the lookup.

| Validator     | Error type       | Default message (en)         | Default message (fr)                       |
| ------------- | ---------------- | ---------------------------- | ------------------------------------------ |
| `email`       | `:invalid`       | "is invalid" (from Rails)    | from Rails' locale files (e.g. rails-i18n) |
| `phone`       | `:invalid`       | "is invalid" (from Rails)    | from Rails' locale files (e.g. rails-i18n) |
| `postal_code` | `:invalid`       | "is invalid" (from Rails)    | from Rails' locale files (e.g. rails-i18n) |
| `mixed_case`  | `:all_caps`      | "cannot be in all caps"      | "ne peut pas être en majuscules"           |
| `mixed_case`  | `:all_lowercase` | "cannot be in all lowercase" | "ne peut pas être en minuscules"           |

Like Rails' own messages, the mixed case messages leave out the attribute's
name, which `full_messages` adds: "First name cannot be in all caps". A custom
message or translation can include it as `%{item}`: the attribute's
translation at `activerecord.attributes.person.<attribute>`, then the
`attribute_name:` option, then the humanized attribute name.

## Credits

- **Email, mixed case, and postal code validators:** [Paul Schreiber](https://paulschreiber.com/), 2010–2011.
- **Phone validator:** written by Kristina Lim, copyright © 2008 Syndeo
  Media. Paul Schreiber added US
  and Canada support (September 2010) and extension support (November 2010).
  It is named after, and was originally built on, Jerrod Blavos's
  [validates_as_phone](https://code.google.com/archive/p/validates-as-phone/) plugin.
- **Gem:** co-authored by Wes Morgan.

## License

Released under the MIT License. See [LICENSE](LICENSE).
