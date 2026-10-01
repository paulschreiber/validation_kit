# frozen_string_literal: true

require "test_helper"
require "open3"
require "rbconfig"
require "tmpdir"

# Each test runs in a fresh process so nothing loaded by other tests (or a
# top-level validator defined here) can leak between them.
class LoadingTest < Minitest::Test
  MODEL = <<~RUBY
    class Contact
      include ActiveModel::Validations
      attr_accessor :email
      validates :email, email: true
    end
    contact = Contact.new
    contact.email = "not an email"
    contact.valid?
    print contact.errors[:email].first
  RUBY

  APP_VALIDATOR = <<~RUBY
    class EmailValidator < ActiveModel::EachValidator
      def validate_each(record, attribute, _value)
        record.errors.add(attribute, "checked by the app")
      end
    end
  RUBY

  def run_ruby(script)
    lib = File.expand_path("../lib", __dir__)
    output, status = Open3.capture2e(RbConfig.ruby, "-I", lib, "-e", script)

    assert_predicate status, :success?, output
    output
  end

  def test_loads_without_rails_or_active_model_preloaded_and_finds_its_validators
    output = run_ruby(%(require "validation_kit"\n#{MODEL}))

    refute_equal "checked by the app", output
    refute_empty output
  end

  def test_an_app_validator_with_the_same_name_wins
    output = run_ruby(%(require "validation_kit"\n#{APP_VALIDATOR}#{MODEL}))

    assert_equal "checked by the app", output
  end

  def test_an_autoloaded_app_validator_with_the_same_name_wins
    Dir.mktmpdir do |dir|
      path = File.join(dir, "email_validator.rb")
      File.write(path, APP_VALIDATOR)
      output = run_ruby(%(require "validation_kit"\nautoload :EmailValidator, #{path.inspect}\n#{MODEL}))

      assert_equal "checked by the app", output
    end
  end

  def test_does_not_add_constants_to_active_model
    script = %(require "validation_kit"\nprint ActiveModel::Validations.const_defined?(:EmailValidator, false))
    output = run_ruby(script)

    assert_equal "false", output
  end
end
