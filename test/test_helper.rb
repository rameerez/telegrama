# frozen_string_literal: true

require "bundler/setup"
Bundler.setup

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

# SimpleCov must be loaded BEFORE any application code
# Configuration is auto-loaded from .simplecov file
require "simplecov"

# Add ActiveJob for testing
require "active_job"

# Then our gem
require "telegrama"

# Test framework
require "minitest/autorun"
require "minitest/mock"

# WebMock for HTTP stubbing (proper test isolation)
require "webmock/minitest"

# Better test output (optional, but nice)
begin
  require "minitest/reporters"
  Minitest::Reporters.use! [Minitest::Reporters::DefaultReporter.new(color: true)]
rescue LoadError
  # minitest-reporters is optional
end

# Configure ActiveJob for testing
ActiveJob::Base.queue_adapter = :test

# Mock ActiveRecord for testing if it's referenced
module ActiveRecord
  class Base
    def self.logger
      @logger ||= Logger.new(nil)
    end
  end
end

# =============================================================================
# Test Helpers Module
# =============================================================================
module TelegramaTestHelpers
  # Default successful Telegram API response
  def successful_telegram_response(chat_id: 123, message_text: "test")
    {
      ok: true,
      result: {
        message_id: rand(1000..9999),
        from: { id: 12345, is_bot: true, first_name: "TestBot", username: "test_bot" },
        chat: { id: chat_id, type: "private" },
        date: Time.now.to_i,
        text: message_text
      }
    }
  end

  # Stub a successful Telegram API sendMessage request
  def stub_telegram_success(chat_id: 123, message_text: nil, &block)
    response_body = successful_telegram_response(chat_id: chat_id, message_text: message_text || "test")

    stub = stub_request(:post, /api\.telegram\.org\/bot.*\/sendMessage/)
      .to_return(
        status: 200,
        body: response_body.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    stub.with(&block) if block_given?
    stub
  end

  # Stub a failed Telegram API request with specific error
  def stub_telegram_failure(error_code: 400, description: "Bad Request")
    stub_request(:post, /api\.telegram\.org\/bot.*\/sendMessage/)
      .to_return(
        status: error_code,
        body: { ok: false, error_code: error_code, description: description }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  # Stub a timeout/network error
  def stub_telegram_timeout
    stub_request(:post, /api\.telegram\.org\/bot.*\/sendMessage/)
      .to_timeout
  end

  # Stub a connection refused error
  def stub_telegram_connection_refused
    stub_request(:post, /api\.telegram\.org\/bot.*\/sendMessage/)
      .to_raise(Errno::ECONNREFUSED)
  end

  # Stub consecutive responses (for testing fallbacks)
  def stub_telegram_consecutive_responses(*responses)
    stub = stub_request(:post, /api\.telegram\.org\/bot.*\/sendMessage/)

    responses.each_with_index do |response, index|
      if response == :success
        stub.to_return(
          status: 200,
          body: successful_telegram_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
      elsif response == :failure
        stub.to_return(
          status: 400,
          body: { ok: false, error_code: 400, description: "Bad Request" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
      elsif response == :timeout
        stub.to_timeout
      elsif response.is_a?(Hash)
        stub.to_return(
          status: response[:status] || 200,
          body: response[:body].to_json,
          headers: { "Content-Type" => "application/json" }
        )
      end
    end

    stub
  end

  # Setup a fresh configuration for isolated testing
  def setup_fresh_configuration
    Telegrama.instance_variable_set(:@configuration, Telegrama::Configuration.new)
    Telegrama.configuration.bot_token = "test-bot-token-#{SecureRandom.hex(8)}"
    Telegrama.configuration.chat_id = rand(100000..999999)
    Telegrama.configuration.default_parse_mode = "MarkdownV2"
    Telegrama.configuration
  end

  # Configure for a specific test scenario
  def configure_telegrama(
    bot_token: "test-bot-token",
    chat_id: 123456,
    parse_mode: "MarkdownV2",
    disable_preview: true,
    prefix: nil,
    suffix: nil,
    formatting: {},
    client_opts: {},
    async: false,
    queue: "default"
  )
    Telegrama.instance_variable_set(:@configuration, Telegrama::Configuration.new)
    cfg = Telegrama.configuration

    cfg.bot_token = bot_token
    cfg.chat_id = chat_id
    cfg.default_parse_mode = parse_mode
    cfg.disable_web_page_preview = disable_preview
    cfg.message_prefix = prefix
    cfg.message_suffix = suffix
    cfg.formatting_options = {
      escape_markdown: true,
      obfuscate_emails: false,
      escape_html: false,
      truncate: 4096
    }.merge(formatting)
    cfg.client_options = {
      timeout: 30,
      retry_count: 3,
      retry_delay: 1
    }.merge(client_opts)
    cfg.deliver_message_async = async
    cfg.deliver_message_queue = queue

    cfg
  end

  # Capture stdout/stderr for testing log output
  def capture_output
    original_stdout = $stdout
    original_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new

    yield

    { stdout: $stdout.string, stderr: $stderr.string }
  ensure
    $stdout = original_stdout
    $stderr = original_stderr
  end

  # Assert that a Telegram API request was made
  def assert_telegram_request_made(times: 1)
    assert_requested(:post, /api\.telegram\.org\/bot.*\/sendMessage/, times: times)
  end

  # Assert that no Telegram API request was made
  def assert_no_telegram_request_made
    assert_not_requested(:post, /api\.telegram\.org\/bot.*\/sendMessage/)
  end

  # Assert that a specific request body was sent
  def assert_telegram_request_with_body(&block)
    assert_requested(:post, /api\.telegram\.org\/bot.*\/sendMessage/) do |request|
      body = JSON.parse(request.body, symbolize_names: true)
      block.call(body)
    end
  end
end

# =============================================================================
# Base Test Class
# =============================================================================
class TelegramaTestCase < Minitest::Test
  include TelegramaTestHelpers

  def setup
    super
    # Disable all network connections by default (WebMock does this, but explicit is good)
    WebMock.disable_net_connect!

    # Setup fresh configuration for each test
    setup_fresh_configuration

    # Clear ActiveJob queue
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
    ActiveJob::Base.queue_adapter.performed_jobs.clear
  end

  def teardown
    super
    # Reset WebMock after each test for complete isolation
    WebMock.reset!

    # Reset configuration
    Telegrama.instance_variable_set(:@configuration, nil)

    # Clear any thread-local state
    Thread.current[:telegrama_parse_mode_override] = nil
  end
end

# Require SecureRandom for test helpers
require "securerandom"
