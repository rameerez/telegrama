require "test_helper"

class Telegrama::ErrorTest < Minitest::Test
  def setup
    Telegrama::TestState.reset
    Telegrama.instance_variable_set(:@configuration, Telegrama::Configuration.new)
    Telegrama.configuration.bot_token = 'token'
    Telegrama.configuration.chat_id = 555
  end

  def test_error_class_exists
    err = Telegrama::Error.new("boom")
    assert_equal "boom", err.message
    assert_kind_of StandardError, err
  end

  def test_client_raises_error
    Telegrama::TestState.should_fail_api_request = true
    Telegrama::TestState.api_failure_count = 0
    Telegrama::TestState.max_api_failures = 1_000

    client = Telegrama::Client.new
    assert_raises(Telegrama::Error) { client.send_message("will always fail") }
  end
end