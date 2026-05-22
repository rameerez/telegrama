# frozen_string_literal: true

require "test_helper"

class Telegrama::ClientTest < TelegramaTestCase
  def setup
    super
    configure_telegrama(
      bot_token: "test-bot-token",
      chat_id: 123456
    )
  end

  # ===========================================================================
  # Basic Send Message Tests
  # ===========================================================================

  def test_send_message_makes_http_request
    stub_telegram_success

    client = Telegrama::Client.new
    client.send_message("Hello, World!")

    assert_telegram_request_made
  end

  def test_send_message_returns_response_object
    stub_telegram_success(chat_id: 123456)

    client = Telegrama::Client.new
    response = client.send_message("Hello, World!")

    assert_kind_of OpenStruct, response
    assert_equal 200, response.code
    assert response.body[:ok]
  end

  def test_send_message_includes_correct_chat_id_in_request
    stub_telegram_success

    client = Telegrama::Client.new
    client.send_message("Test message")

    assert_telegram_request_with_body do |body|
      body[:chat_id] == 123456
    end
  end

  def test_send_message_includes_text_in_request
    stub_telegram_success

    client = Telegrama::Client.new
    client.send_message("Test message content")

    assert_telegram_request_with_body do |body|
      body[:text].include?("Test message content")
    end
  end

  def test_send_message_includes_parse_mode_in_request
    stub_telegram_success

    client = Telegrama::Client.new
    client.send_message("Test message")

    assert_telegram_request_with_body do |body|
      body[:parse_mode] == "MarkdownV2"
    end
  end

  def test_send_message_includes_disable_web_page_preview
    stub_telegram_success

    client = Telegrama::Client.new
    client.send_message("Test message")

    assert_telegram_request_with_body do |body|
      body[:disable_web_page_preview] == true
    end
  end

  # ===========================================================================
  # Chat ID Override Tests
  # ===========================================================================

  def test_send_message_can_override_chat_id
    stub_telegram_success

    client = Telegrama::Client.new
    client.send_message("Test message", chat_id: 999999)

    assert_telegram_request_with_body do |body|
      body[:chat_id] == 999999
    end
  end

  def test_send_message_with_string_chat_id
    stub_telegram_success

    client = Telegrama::Client.new
    client.send_message("Test message", chat_id: "@mychannel")

    assert_telegram_request_with_body do |body|
      body[:chat_id] == "@mychannel"
    end
  end

  def test_send_message_with_negative_chat_id_for_groups
    stub_telegram_success

    client = Telegrama::Client.new
    client.send_message("Test message", chat_id: -1001234567890)

    assert_telegram_request_with_body do |body|
      body[:chat_id] == -1001234567890
    end
  end

  # ===========================================================================
  # Forum Topic Tests
  # ===========================================================================

  def test_send_message_omits_message_thread_id_by_default
    stub_telegram_success

    client = Telegrama::Client.new
    client.send_message("Test message")

    assert_telegram_request_with_body do |body|
      !body.key?(:message_thread_id)
    end
  end

  def test_send_message_includes_message_thread_id_when_provided
    stub_telegram_success

    client = Telegrama::Client.new
    client.send_message("Test message", message_thread_id: 42)

    assert_telegram_request_with_body do |body|
      body[:message_thread_id] == 42
    end
  end

  def test_send_message_accepts_message_thread_id_with_string_key
    stub_telegram_success

    client = Telegrama::Client.new
    client.send_message("Test message", "message_thread_id" => 42)

    assert_telegram_request_with_body do |body|
      body[:message_thread_id] == 42
    end
  end

  def test_send_message_uses_configured_default_message_thread_id
    Telegrama.configuration.message_thread_id = 101
    stub_telegram_success

    client = Telegrama::Client.new
    client.send_message("Test message")

    assert_telegram_request_with_body do |body|
      body[:message_thread_id] == 101
    end
  end

  def test_send_message_can_override_configured_message_thread_id
    Telegrama.configuration.message_thread_id = 101
    stub_telegram_success

    client = Telegrama::Client.new
    client.send_message("Test message", message_thread_id: 202)

    assert_telegram_request_with_body do |body|
      body[:message_thread_id] == 202
    end
  end

  def test_send_message_can_disable_configured_message_thread_id_with_nil
    Telegrama.configuration.message_thread_id = 101
    stub_telegram_success

    client = Telegrama::Client.new
    client.send_message("Test message", message_thread_id: nil)

    assert_telegram_request_with_body do |body|
      !body.key?(:message_thread_id)
    end
  end

  def test_send_message_can_disable_configured_message_thread_id_with_string_key_nil
    Telegrama.configuration.message_thread_id = 101
    stub_telegram_success

    client = Telegrama::Client.new
    client.send_message("Test message", "message_thread_id" => nil)

    assert_telegram_request_with_body do |body|
      !body.key?(:message_thread_id)
    end
  end

  def test_send_message_preserves_message_thread_id_when_falling_back
    stub_request(:post, /api\.telegram\.org\/bot.*\/sendMessage/)
      .to_return(
        { status: 400, body: { ok: false, description: "Bad Request: can't parse entities" }.to_json },
        { status: 200, body: successful_telegram_response.to_json }
      )

    client = Telegrama::Client.new
    response = client.send_message("*bold* text", message_thread_id: 303)

    assert_equal 200, response.code
    assert_requested(:post, /api\.telegram\.org\/bot.*\/sendMessage/, times: 2) do |request|
      JSON.parse(request.body, symbolize_names: true)[:message_thread_id] == 303
    end
  end

  def test_send_message_preserves_message_thread_id_through_plain_text_fallback
    stub_request(:post, /api\.telegram\.org\/bot.*\/sendMessage/)
      .to_return(
        { status: 400, body: { ok: false, description: "Bad Request: can't parse entities" }.to_json },
        { status: 400, body: { ok: false, description: "Bad Request: can't parse entities" }.to_json },
        { status: 200, body: successful_telegram_response.to_json }
      )

    client = Telegrama::Client.new
    response = client.send_message("*bold* text", message_thread_id: 303)

    assert_equal 200, response.code

    requests = WebMock::RequestRegistry.instance.requested_signatures.hash.keys
    payloads = requests.map { |request| JSON.parse(request.body, symbolize_names: true) }

    assert_equal [303, 303, 303], payloads.map { |payload| payload[:message_thread_id] }
    refute payloads.last.key?(:parse_mode)
  end

  def test_send_message_does_not_mutate_options
    stub_telegram_success

    options = {
      chat_id: 999,
      message_thread_id: 42,
      parse_mode: "HTML",
      formatting: { escape_html: true },
      disable_web_page_preview: false
    }
    original_options = Marshal.load(Marshal.dump(options))

    client = Telegrama::Client.new
    client.send_message("Test message", options)

    assert_equal original_options, options
  end

  def test_send_message_rejects_zero_message_thread_id
    client = Telegrama::Client.new

    error = assert_raises(ArgumentError) do
      client.send_message("Test message", message_thread_id: 0)
    end

    assert_includes error.message, "message_thread_id"
    assert_no_telegram_request_made
  end

  def test_send_message_rejects_negative_message_thread_id
    client = Telegrama::Client.new

    error = assert_raises(ArgumentError) do
      client.send_message("Test message", message_thread_id: -1)
    end

    assert_includes error.message, "message_thread_id"
    assert_no_telegram_request_made
  end

  def test_send_message_rejects_string_message_thread_id
    client = Telegrama::Client.new

    error = assert_raises(ArgumentError) do
      client.send_message("Test message", message_thread_id: "42")
    end

    assert_includes error.message, "message_thread_id"
    assert_no_telegram_request_made
  end

  # ===========================================================================
  # Parse Mode Override Tests
  # ===========================================================================

  def test_send_message_can_override_parse_mode_to_html
    stub_telegram_success

    client = Telegrama::Client.new
    client.send_message("Test message", parse_mode: "HTML")

    assert_telegram_request_with_body do |body|
      body[:parse_mode] == "HTML"
    end
  end

  def test_send_message_can_set_parse_mode_to_nil
    stub_telegram_success

    client = Telegrama::Client.new
    client.send_message("Test message", parse_mode: nil)

    assert_telegram_request_with_body do |body|
      !body.key?(:parse_mode)
    end
  end

  def test_send_message_with_nil_parse_mode_sends_plain_text_without_markdown_escaping
    Telegrama.configuration.message_prefix = "*~ Test App ~*\n\n"
    stub_telegram_success

    message = "Timestamp UTC: 2026-05-22T01:30:01Z\n" \
              "Gem: telegrama 0.3.0\n" \
              "Bot: @test_bot (id 123, is_bot true)\n" \
              "Chat ID: -1003778147828\n" \
              "Topic/message_thread_id: 5019"

    client = Telegrama::Client.new
    client.send_message(message, parse_mode: nil)

    assert_telegram_request_with_body do |body|
      !body.key?(:parse_mode) &&
        body[:text] == "*~ Test App ~*\n\n#{message}"
    end
  end

  def test_send_message_omits_parse_mode_when_default_parse_mode_is_nil
    Telegrama.configuration.default_parse_mode = nil
    Telegrama.configuration.message_prefix = "*~ Test App ~*\n\n"
    stub_telegram_success

    client = Telegrama::Client.new
    client.send_message("Version 0.3.0 (plain text)")

    assert_telegram_request_with_body do |body|
      !body.key?(:parse_mode) &&
        body[:text] == "*~ Test App ~*\n\nVersion 0.3.0 (plain text)"
    end
  end

  def test_send_message_with_html_parse_mode_does_not_markdown_escape
    stub_telegram_success

    client = Telegrama::Client.new
    client.send_message("Version 0.3.0 & <ok>", parse_mode: "HTML")

    assert_telegram_request_with_body do |body|
      body[:parse_mode] == "HTML" &&
        body[:text] == "Version 0.3.0 &amp; &lt;ok&gt;"
    end
  end

  def test_send_message_with_markdownv2_escapes_identifier_underscores
    stub_telegram_success

    client = Telegrama::Client.new
    client.send_message("Bot is_bot true; Topic message_thread_id; Method send_message")

    assert_telegram_request_with_body do |body|
      body[:parse_mode] == "MarkdownV2" &&
        body[:text].include?("is\\_bot") &&
        body[:text].include?("message\\_thread\\_id") &&
        body[:text].include?("send\\_message")
    end
  end

  # ===========================================================================
  # Web Page Preview Tests
  # ===========================================================================

  def test_send_message_can_enable_web_page_preview
    stub_telegram_success

    client = Telegrama::Client.new
    client.send_message("Check out https://example.com", disable_web_page_preview: false)

    assert_telegram_request_with_body do |body|
      body[:disable_web_page_preview] == false
    end
  end

  # ===========================================================================
  # Client Options Tests
  # ===========================================================================

  def test_client_can_be_initialized_with_custom_config
    stub_telegram_success

    client = Telegrama::Client.new(timeout: 60)
    response = client.send_message("Test")

    assert_equal 200, response.code
  end

  # ===========================================================================
  # API Error Handling Tests
  # ===========================================================================

  def test_raises_error_on_api_failure
    stub_telegram_failure(error_code: 400, description: "Bad Request: chat not found")

    client = Telegrama::Client.new
    error = assert_raises(Telegrama::Error) { client.send_message("Test") }
    assert_includes error.message, "chat not found"
  end

  def test_raises_error_on_unauthorized
    stub_telegram_failure(error_code: 401, description: "Unauthorized")

    client = Telegrama::Client.new
    error = assert_raises(Telegrama::Error) { client.send_message("Test") }
    assert_includes error.message, "Unauthorized"
  end

  def test_raises_error_on_forbidden
    stub_telegram_failure(error_code: 403, description: "Forbidden: bot was blocked by the user")

    client = Telegrama::Client.new
    error = assert_raises(Telegrama::Error) { client.send_message("Test") }
    assert_includes error.message, "bot was blocked"
  end

  def test_raises_error_on_not_found
    stub_telegram_failure(error_code: 404, description: "Not Found")

    client = Telegrama::Client.new
    error = assert_raises(Telegrama::Error) { client.send_message("Test") }
    assert_includes error.message, "Not Found"
  end

  def test_raises_error_on_rate_limit
    stub_telegram_failure(error_code: 429, description: "Too Many Requests: retry after 35")

    client = Telegrama::Client.new
    error = assert_raises(Telegrama::Error) { client.send_message("Test") }
    assert_includes error.message, "Too Many Requests"
  end

  def test_raises_error_on_server_error
    stub_telegram_failure(error_code: 500, description: "Internal Server Error")

    client = Telegrama::Client.new
    error = assert_raises(Telegrama::Error) { client.send_message("Test") }
    assert_includes error.message, "Internal Server Error"
  end

  # ===========================================================================
  # Network Error Tests
  # ===========================================================================

  def test_raises_error_on_timeout
    stub_telegram_timeout

    client = Telegrama::Client.new
    error = assert_raises(Telegrama::Error) { client.send_message("Test") }
    assert_includes error.message, "Failed to send Telegram message"
  end

  def test_raises_error_on_connection_refused
    stub_telegram_connection_refused

    client = Telegrama::Client.new
    error = assert_raises(Telegrama::Error) { client.send_message("Test") }
    assert_includes error.message, "Failed to send Telegram message"
  end

  # ===========================================================================
  # Fallback Strategy Tests
  # ===========================================================================

  def test_fallback_from_markdownv2_to_html
    # First request (MarkdownV2) fails, second request (HTML) succeeds
    stub_request(:post, /api\.telegram\.org\/bot.*\/sendMessage/)
      .to_return(
        { status: 400, body: { ok: false, description: "Bad Request: can't parse entities" }.to_json },
        { status: 200, body: successful_telegram_response.to_json }
      )

    client = Telegrama::Client.new
    response = client.send_message("*bold* text")

    assert_equal 200, response.code
    assert_telegram_request_made(times: 2)
  end

  def test_fallback_from_html_to_plain_text
    # First request (MarkdownV2) fails, second (HTML) fails, third (plain) succeeds
    stub_request(:post, /api\.telegram\.org\/bot.*\/sendMessage/)
      .to_return(
        { status: 400, body: { ok: false, description: "Bad Request: can't parse entities" }.to_json },
        { status: 400, body: { ok: false, description: "Bad Request: can't parse entities" }.to_json },
        { status: 200, body: successful_telegram_response.to_json }
      )

    client = Telegrama::Client.new
    response = client.send_message("<b>bold</b> text")

    assert_equal 200, response.code
    assert_telegram_request_made(times: 3)
  end

  def test_plain_text_fallback_omits_parse_mode
    stub_request(:post, /api\.telegram\.org\/bot.*\/sendMessage/)
      .to_return(
        { status: 400, body: { ok: false, description: "Bad Request: can't parse entities" }.to_json },
        { status: 400, body: { ok: false, description: "Bad Request: can't parse entities" }.to_json },
        { status: 200, body: successful_telegram_response.to_json }
      )

    client = Telegrama::Client.new
    response = client.send_message("*bold* text")

    assert_equal 200, response.code

    requests = WebMock::RequestRegistry.instance.requested_signatures.hash.keys
    payloads = requests.map { |request| JSON.parse(request.body, symbolize_names: true) }

    assert_equal "MarkdownV2", payloads[0][:parse_mode]
    assert_equal "HTML", payloads[1][:parse_mode]
    refute payloads[2].key?(:parse_mode)
  end

  def test_raises_error_after_all_fallbacks_exhausted
    stub_telegram_failure(error_code: 400, description: "Bad Request")

    client = Telegrama::Client.new
    assert_raises(Telegrama::Error) { client.send_message("Test") }

    # Should have tried all 3 formats
    assert_telegram_request_made(times: 3)
  end

  # ===========================================================================
  # Response Body Tests
  # ===========================================================================

  def test_response_body_contains_message_id
    stub_telegram_success

    client = Telegrama::Client.new
    response = client.send_message("Test")

    refute_nil response.body[:result][:message_id]
  end

  def test_response_body_contains_chat_info
    stub_telegram_success(chat_id: 123456)

    client = Telegrama::Client.new
    response = client.send_message("Test")

    assert_equal 123456, response.body[:result][:chat][:id]
  end

  def test_response_body_contains_from_info
    stub_telegram_success

    client = Telegrama::Client.new
    response = client.send_message("Test")

    assert response.body[:result][:from][:is_bot]
    refute_nil response.body[:result][:from][:first_name]
  end

  def test_response_body_contains_date
    stub_telegram_success

    client = Telegrama::Client.new
    response = client.send_message("Test")

    refute_nil response.body[:result][:date]
    assert_kind_of Integer, response.body[:result][:date]
  end

  # ===========================================================================
  # Invalid JSON Response Tests
  # ===========================================================================

  def test_handles_invalid_json_response
    stub_request(:post, /api\.telegram\.org\/bot.*\/sendMessage/)
      .to_return(
        status: 200,
        body: "not valid json",
        headers: { "Content-Type" => "application/json" }
      )

    client = Telegrama::Client.new
    error = assert_raises(Telegrama::Error) { client.send_message("Test") }
    assert_includes error.message, "Invalid JSON"
  end

  # ===========================================================================
  # API URL Tests
  # ===========================================================================

  def test_uses_correct_telegram_api_url
    stub_telegram_success

    client = Telegrama::Client.new
    client.send_message("Test")

    assert_requested(:post, "https://api.telegram.org/bottest-bot-token/sendMessage")
  end

  # ===========================================================================
  # Edge Cases
  # ===========================================================================

  def test_can_send_empty_string_message
    stub_telegram_success

    client = Telegrama::Client.new
    response = client.send_message("")

    assert_equal 200, response.code
  end

  def test_can_send_very_long_message
    stub_telegram_success

    client = Telegrama::Client.new
    long_message = "x" * 5000  # Exceeds Telegram's 4096 limit, should be truncated
    response = client.send_message(long_message)

    assert_equal 200, response.code
  end

  def test_can_send_unicode_message
    stub_telegram_success

    client = Telegrama::Client.new
    response = client.send_message("Привет мир! 🌍 こんにちは 你好")

    assert_equal 200, response.code
  end

  def test_can_send_message_with_emoji
    stub_telegram_success

    client = Telegrama::Client.new
    response = client.send_message("🚀 Launched! 🎉")

    assert_equal 200, response.code
  end

  def test_can_send_multiline_message
    stub_telegram_success

    message = <<~MSG
      Line 1
      Line 2
      Line 3
    MSG

    client = Telegrama::Client.new
    response = client.send_message(message)

    assert_equal 200, response.code
  end

  def test_multiple_clients_are_independent
    stub_telegram_success

    client1 = Telegrama::Client.new
    client2 = Telegrama::Client.new(timeout: 120)

    # Both should work independently
    response1 = client1.send_message("From client 1")
    response2 = client2.send_message("From client 2")

    assert_equal 200, response1.code
    assert_equal 200, response2.code
    assert_telegram_request_made(times: 2)
  end
end
