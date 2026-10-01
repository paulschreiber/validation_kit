# frozen_string_literal: true

require "test_helper"
require "open3"
require "rbconfig"

class LoadingTest < Minitest::Test
  # Run in a fresh process so nothing loaded by other tests can mask a
  # missing require.
  def test_loads_without_rails_or_active_model_preloaded
    script = 'require "validation_kit"; print ActiveModel::Validations::EmailValidator.name'
    lib = File.expand_path("../lib", __dir__)
    output, status = Open3.capture2e(RbConfig.ruby, "-I", lib, "-e", script)

    assert_predicate status, :success?, output
    assert_equal "ValidationKit::EmailValidator", output
  end
end
