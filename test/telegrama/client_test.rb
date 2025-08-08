require "test_helper"

class Telegrama::ClientTest < Minitest::Test
  def setup
    Telegrama::TestState.reset
    Telegrama.instance_variable_set(:@configuration, Telegrama::Configuration.new)
    Telegrama.configuration.bot_token = 'test-token'
    Telegrama.configuration.chat_id = 111
    Telegrama.configuration.default_parse_mode = 'MarkdownV2'
  end

  def test_send_message_happy_path
    client = Telegrama::Client.new
    response = client.send_message("hello")
    assert_equal 200, response.code
    assert response.body[:ok]
    assert_equal 111, response.body[:result][:chat][:id]
    assert_equal 'hello', response.body[:result][:text]
  end

  def test_overrides_chat_id_and_parse_mode
    client = Telegrama::Client.new
    response = client.send_message("<b>html</b>", chat_id: 222, parse_mode: 'HTML', disable_web_page_preview: false)
    assert_equal 200, response.code
    assert_equal 222, response.body[:result][:chat][:id]
    # text will be escaped because escape_html is turned on in client for HTML parse mode
    assert_includes response.body[:result][:text], '&lt;b&gt;html&lt;/b&gt;'
  end

  def test_merges_client_options
    client = Telegrama::Client.new(timeout: 2)
    # Will use mocked perform_request in tests, but ensure it still returns ok
    response = client.send_message("config")
    assert_equal 200, response.code
  end

  def test_fallback_to_html_then_plain
    # First attempt fails (Markdown), second also fails (HTML), third succeeds (plain)
    Telegrama::TestState.should_fail_api_request = true
    Telegrama::TestState.api_failure_count = 0
    Telegrama::TestState.max_api_failures = 2

    client = Telegrama::Client.new
    response = client.send_message("*bad markdown* <b>html</b>")
    assert_equal 200, response.code
  end

  def test_raises_error_after_exhausting_fallbacks
    Telegrama::TestState.should_fail_api_request = true
    Telegrama::TestState.api_failure_count = 0
    Telegrama::TestState.max_api_failures = 3

    client = Telegrama::Client.new
    assert_raises(Telegrama::Error) { client.send_message("will fail repeatedly") }
  end
end