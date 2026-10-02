# Changelog

## Unreleased

### Breaking changes

- A symbol `country:` option that's neither a method on the model nor a
  two-letter country code (such as a misspelled method name,
  `country: :billing_contry`) now raises `ArgumentError` when validating. It
  used to fall back to the model's `country` method, or skip validation
  silently.
- The bundled mixed case messages no longer start with the attribute's name, so
  `full_messages` names it once ("First name cannot be in all caps", not "First
  name First name cannot be in all caps"), like Rails' own messages:
  - `errors[:first_name]` is now `["cannot be in all caps"]`. Code that shows
    `errors[attribute]` on its own should use `full_messages_for` instead.
  - `attribute_name:` no longer changes the default message. `full_messages`
    uses the attribute's translated name (`human_attribute_name`) instead; to
    rename it, translate the attribute. `attribute_name:` still fills in
    `%{item}` in custom messages and translations, which keep working.
  - Apps that set `errors.format` to `"%{message}"` to hide the doubled name now
    get messages with no name at all, and can drop that setting.

### Changed

- US and Canadian phone numbers with extra digits right after the number and no
  extension marker in front of them (any letter, as in `x`, `ext` or
  `extension`, or `#`, `＃` or `№`) are now invalid, with or without `set:`. A
  mistyped number such as `212-555-12345` used to pass, and `set:` stored it as
  `(212) 555-1234 5`. This includes non-ASCII digits such as `５`.
- Without `set:`, a US or Canadian number with letters among its first ten
  digits (`519 444 000 ext 123`) is now invalid, as it already was with `set:`.
- With `set:`, a stored extension no longer keeps a leading `,` or `;` or
  surrounding spaces (including non-breaking ones): `212-555-1234, ext 5`
  becomes `(212) 555-1234 ext 5`. An extension written with non-ASCII digits
  (`x５`) is kept instead of being dropped. Other marked extensions (`x5`,
  `ext. 99`, `(x5)`, `#5`, …) are stored as before.
### Fixed

- `country: :CA` (or `:ca`) now validates as Canada, as the README says. A
  symbol was only ever treated as a method name, so without a `CA` method the
  validator used the model's `country` method instead, or skipped validation
  silently.
- The phone validator's `area_key:` (and `format_as_phone`'s area key) now
  accepts Australian states in any case, as a string or symbol, like country
  codes. `:vic` or `"vic"` used to silently get the NSW/ACT area code (02).

## 2.0.0 (2026-10-01)

### Breaking changes

- **Ruby 3.4+ and activemodel 7.2+ are required.** The gem now declares its
  activemodel dependency and loads without Rails.
- **Errors are added by type instead of as translated strings.** All four
  validators call `errors.add(attribute, :invalid)` (mixed case:
  `:all_caps` / `:all_lowercase`), so `errors.added?(:email, :invalid)` and
  `errors.details` work, and ActiveModel does the message lookup.
  - Existing `activerecord.errors.models.<model>.attributes.<attribute>.<type>`
    translations keep working.
  - Non-ActiveRecord models now look under `activemodel.*` instead of
    `activerecord.*`, and fall back to Rails' "is invalid".
  - A `message:` (or `all_caps:` / `all_lowercase:`) option now takes
    precedence over translations, as it does for Rails' own validators.
  - The bundled mixed case messages moved from `activerecord.errors.messages`
    to `errors.messages`.
- **`ActiveModel::Validations::EmailValidator` (and `PhoneValidator`,
  `PostalCodeValidator`, `MixedCaseValidator`) no longer exist.** Use
  `ValidationKit::EmailValidator` and so on. `validates :email, email: true`
  is unchanged, and an app's own validator with the same name now takes
  precedence over the gem's.
- **`MixedCaseValidator::ALL_CAPS` / `ALL_LOWERCASE`** are now the symbols
  `:all_caps` / `:all_lowercase` instead of `1` / `-1`.
- **Validation is stricter**, so some values that used to pass are now
  invalid:
  - postal codes of the wrong length (e.g. a 7-digit US ZIP code)
  - email addresses containing a newline
  - phone and postal input that's blank once cleaned up (e.g. `"n/a"`), even
    with `allow_blank`
- **`format_as_phone` returns `nil`** for numbers it can't format, instead of
  the raw digits.

### Fixed

- The email regex no longer backtracks catastrophically: crafted input that
  took over a minute to reject now fails in under a millisecond.
- Postal codes of the wrong length were accepted and then replaced with `nil`
  by `set:`.
- With `allow_blank`, junk phone and postal input was accepted and replaced
  with `""` or `nil`.
- US/CA numbers with a leading 1 (`1-212-555-1234`) were stored with a
  trailing space.
- Phone extensions could be taken from the wrong part of the input when the
  last four digits appeared earlier in it.
- Country codes in lowercase or as symbols (`"us"`, `:US`) silently skipped
  validation.
- Integer values (e.g. a ZIP code from an integer column) raised instead of
  validating.
- Mixed case errors were missing the attribute name and ignored the
  `attribute_name:` option, and the bundled English and French messages were
  never loaded.
- Values with no letters (`"123"`) or in scripts without case failed as "all
  caps", and short accented names skipped the check.
- A stray `|` in the AU phone regex character classes.

### Added

- UK postcode validation and formatting (`UK` or `GB`).
- `source_code_uri`, `bug_tracker_uri`, and `changelog_uri` gemspec metadata,
  and a declared MIT license.

### Documentation

- One `README.md` replaces the per-validator READMEs, with current usage,
  options, and a translation key reference. Added `LICENSE` and this
  changelog.

### Internal

- Minitest suite, CI on Ruby 3.4/4.0 against activemodel 7.2/8.0/8.1,
  rubocop, Dependabot, and a trusted publishing release workflow. The gem now
  packages only `lib/`, `README.md`, `LICENSE`, and `CHANGELOG.md`.

## 1.0.5

Last release before 2.0.0.
