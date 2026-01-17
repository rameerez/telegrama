# frozen_string_literal: true

require "test_helper"

class TelegramaModuleTest < TelegramaTestCase
  # ===========================================================================
  # Module Structure Tests
  # ===========================================================================

  def test_module_exists
    assert defined?(Telegrama)
  end

  def test_version_constant_exists
    assert defined?(Telegrama::VERSION)
  end

  def test_error_class_exists
    assert defined?(Telegrama::Error)
  end

  def test_configuration_class_exists
    assert defined?(Telegrama::Configuration)
  end

  def test_client_class_exists
    assert defined?(Telegrama::Client)
  end

  def test_formatter_module_exists
    assert defined?(Telegrama::Formatter)
  end

  def test_send_message_job_class_exists
    assert defined?(Telegrama::SendMessageJob)
  end

  # ===========================================================================
  # Configuration Method Tests
  # ===========================================================================

  def test_configuration_returns_configuration_object
    config = Telegrama.configuration
    assert_kind_of Telegrama::Configuration, config
  end

  def test_configuration_is_memoized
    config1 = Telegrama.configuration
    config2 = Telegrama.configuration
    assert_same config1, config2
  end

  def test_configure_yields_configuration
    yielded = nil
    Telegrama.configure do |config|
      config.bot_token = "test-token"
      yielded = config
    end

    assert_kind_of Telegrama::Configuration, yielded
  end

  def test_configure_validates_configuration
    error = assert_raises(ArgumentError) do
      Telegrama.configure do |config|
        config.bot_token = nil  # Invalid
      end
    end
    assert_includes error.message, "bot_token"
  end

  def test_configure_sets_values
    Telegrama.configure do |config|
      config.bot_token = "new-token"
      config.chat_id = 999
    end

    assert_equal "new-token", Telegrama.configuration.bot_token
    assert_equal 999, Telegrama.configuration.chat_id
  end

  # ===========================================================================
  # send_message Method Tests
  # ===========================================================================

  def test_send_message_validates_configuration
    Telegrama.instance_variable_set(:@configuration, Telegrama::Configuration.new)
    Telegrama.configuration.bot_token = nil

    error = assert_raises(ArgumentError) { Telegrama.send_message("Test") }
    assert_includes error.message, "bot_token"
  end

  def test_send_message_synchronous
    stub_telegram_success

    configure_telegrama(
      bot_token: "test-token",
      chat_id: 123,
      async: false
    )

    response = Telegrama.send_message("Sync message")

    assert_equal 200, response.code
    assert_telegram_request_made
  end

  def test_send_message_asynchronous
    configure_telegrama(
      bot_token: "test-token",
      chat_id: 123,
      async: true,
      queue: "critical"
    )

    before_count = ActiveJob::Base.queue_adapter.enqueued_jobs.size
    Telegrama.send_message("Async message")
    after_count = ActiveJob::Base.queue_adapter.enqueued_jobs.size

    assert_equal before_count + 1, after_count
  end

  def test_send_message_passes_options
    stub_telegram_success

    configure_telegrama(
      bot_token: "test-token",
      chat_id: 123
    )

    Telegrama.send_message("Test", chat_id: 999, parse_mode: "HTML")

    assert_telegram_request_with_body do |body|
      body[:chat_id] == 999 && body[:parse_mode] == "HTML"
    end
  end

  def test_send_message_uses_default_chat_id
    stub_telegram_success

    configure_telegrama(
      bot_token: "test-token",
      chat_id: 12345
    )

    Telegrama.send_message("Test")

    assert_telegram_request_with_body do |body|
      body[:chat_id] == 12345
    end
  end

  # ===========================================================================
  # Logging Method Tests
  # ===========================================================================

  def test_log_error_exists
    assert Telegrama.respond_to?(:log_error)
  end

  def test_log_info_exists
    assert Telegrama.respond_to?(:log_info)
  end

  def test_log_error_outputs_to_stderr
    output = capture_output do
      Telegrama.log_error("Test error message")
    end

    assert_includes output[:stderr], "[Telegrama]"
    assert_includes output[:stderr], "Test error message"
  end

  def test_log_info_outputs_to_stdout
    output = capture_output do
      Telegrama.log_info("Test info message")
    end

    assert_includes output[:stdout], "[Telegrama]"
    assert_includes output[:stdout], "Test info message"
  end

  # ===========================================================================
  # Full Integration Tests
  # ===========================================================================

  def test_full_workflow_sync
    stub_telegram_success

    # Configure the gem
    Telegrama.configure do |config|
      config.bot_token = "integration-test-token"
      config.chat_id = 123456
      config.default_parse_mode = "MarkdownV2"
      config.message_prefix = "[TEST] "
      config.formatting_options = {
        escape_markdown: true,
        obfuscate_emails: true,
        truncate: 4096
      }
      config.deliver_message_async = false
    end

    # Send a message
    response = Telegrama.send_message("*Hello* from integration test!")

    # Verify response
    assert_equal 200, response.code
    assert response.body[:ok]

    # Verify the request was made correctly
    assert_telegram_request_with_body do |body|
      body[:chat_id] == 123456 &&
        body[:parse_mode] == "MarkdownV2" &&
        body[:text].include?("[TEST]") &&
        body[:text].include?("Hello")
    end
  end

  def test_full_workflow_async
    # Configure the gem for async
    Telegrama.configure do |config|
      config.bot_token = "async-test-token"
      config.chat_id = 789
      config.deliver_message_async = true
      config.deliver_message_queue = "notifications"
    end

    # Send a message
    before_count = ActiveJob::Base.queue_adapter.enqueued_jobs.size
    Telegrama.send_message("Async integration test!")
    after_count = ActiveJob::Base.queue_adapter.enqueued_jobs.size

    # Verify job was enqueued
    assert_equal before_count + 1, after_count

    enqueued = ActiveJob::Base.queue_adapter.enqueued_jobs.last
    assert_equal "notifications", enqueued[:queue]
    assert_equal "Async integration test!", enqueued[:args][0]
  end

  def test_multiple_messages_same_config
    stub_telegram_success

    configure_telegrama(
      bot_token: "multi-test-token",
      chat_id: 123
    )

    # Send multiple messages
    response1 = Telegrama.send_message("Message 1")
    response2 = Telegrama.send_message("Message 2")
    response3 = Telegrama.send_message("Message 3")

    assert_equal 200, response1.code
    assert_equal 200, response2.code
    assert_equal 200, response3.code

    assert_telegram_request_made(times: 3)
  end

  def test_different_chat_ids_same_session
    stub_telegram_success

    configure_telegrama(
      bot_token: "multi-chat-token",
      chat_id: 111
    )

    # Send to different chats
    Telegrama.send_message("To default", chat_id: 111)
    Telegrama.send_message("To marketing", chat_id: 222)
    Telegrama.send_message("To support", chat_id: 333)

    assert_telegram_request_made(times: 3)
  end

  # ===========================================================================
  # Error Handling Integration Tests
  # ===========================================================================

  def test_api_error_propagates_through_send_message
    stub_telegram_failure(error_code: 403, description: "Forbidden: bot was blocked")

    configure_telegrama(
      bot_token: "error-test-token",
      chat_id: 123
    )

    error = assert_raises(Telegrama::Error) do
      Telegrama.send_message("Test")
    end

    assert_includes error.message, "Forbidden"
  end

  def test_network_error_propagates_through_send_message
    stub_telegram_timeout

    configure_telegrama(
      bot_token: "timeout-test-token",
      chat_id: 123
    )

    assert_raises(Telegrama::Error) do
      Telegrama.send_message("Test")
    end
  end

  # ===========================================================================
  # Configuration Reset Tests
  # ===========================================================================

  def test_configuration_can_be_reset
    configure_telegrama(bot_token: "first-token", chat_id: 100)
    assert_equal "first-token", Telegrama.configuration.bot_token

    # Reset and reconfigure
    Telegrama.instance_variable_set(:@configuration, nil)

    Telegrama.configure do |config|
      config.bot_token = "second-token"
      config.chat_id = 200
    end

    assert_equal "second-token", Telegrama.configuration.bot_token
    assert_equal 200, Telegrama.configuration.chat_id
  end

  # ===========================================================================
  # Concurrent Usage Tests (basic)
  # ===========================================================================

  def test_configuration_is_thread_safe_for_reading
    configure_telegrama(
      bot_token: "thread-safe-token",
      chat_id: 123
    )

    results = []
    threads = 5.times.map do
      Thread.new do
        results << Telegrama.configuration.bot_token
      end
    end

    threads.each(&:join)

    assert_equal 5, results.size
    assert results.all? { |r| r == "thread-safe-token" }
  end

  # ===========================================================================
  # Edge Cases
  # ===========================================================================

  def test_send_message_with_nil_message
    stub_telegram_success

    configure_telegrama(bot_token: "test-token", chat_id: 123)

    # nil gets converted to empty string by formatter
    response = Telegrama.send_message(nil)
    assert_equal 200, response.code
  end

  def test_send_message_with_non_string_message
    stub_telegram_success

    configure_telegrama(bot_token: "test-token", chat_id: 123)

    # Numbers should be converted to string
    response = Telegrama.send_message(12345)
    assert_equal 200, response.code
  end

  def test_send_message_with_symbol_message
    stub_telegram_success

    configure_telegrama(bot_token: "test-token", chat_id: 123)

    response = Telegrama.send_message(:test_symbol)
    assert_equal 200, response.code
  end
end
