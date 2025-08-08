require "test_helper"

class Telegrama::VersionTest < Minitest::Test
  def test_version_defined
    refute_nil Telegrama::VERSION
    assert_match /\A\d+\.\d+\.\d+\z/, Telegrama::VERSION
  end
end