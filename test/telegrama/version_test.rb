# frozen_string_literal: true

require "test_helper"

class Telegrama::VersionTest < TelegramaTestCase
  def test_version_is_defined
    refute_nil Telegrama::VERSION
  end

  def test_version_is_a_string
    assert_kind_of String, Telegrama::VERSION
  end

  def test_version_follows_semver_format
    # Semantic versioning: MAJOR.MINOR.PATCH
    assert_match(/\A\d+\.\d+\.\d+\z/, Telegrama::VERSION)
  end

  def test_version_is_frozen
    # Good practice for constants
    assert Telegrama::VERSION.frozen?
  end

  def test_version_parts_are_valid_numbers
    major, minor, patch = Telegrama::VERSION.split(".").map(&:to_i)

    assert_operator major, :>=, 0, "Major version should be non-negative"
    assert_operator minor, :>=, 0, "Minor version should be non-negative"
    assert_operator patch, :>=, 0, "Patch version should be non-negative"
  end

  def test_current_version_is_expected
    # Update this when version changes
    assert_equal "0.1.3", Telegrama::VERSION
  end
end
