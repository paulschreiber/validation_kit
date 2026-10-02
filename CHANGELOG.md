# Changelog

## Unreleased

### Fixed

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
