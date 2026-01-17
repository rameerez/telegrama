# frozen_string_literal: true

require "test_helper"

class Telegrama::ConfigurationTest < TelegramaTestCase
  def setup
    super
    # Create a fresh configuration for each test
    @config = Telegrama::Configuration.new
  end

  # ===========================================================================
  # Default Values Tests
  # ===========================================================================

  def test_defaults_bot_token_is_nil
    assert_nil @config.bot_token
  end

  def test_defaults_chat_id_is_nil
    assert_nil @config.chat_id
  end

  def test_defaults_parse_mode_is_markdownv2
    assert_equal "MarkdownV2", @config.default_parse_mode
  end

  def test_defaults_disable_web_page_preview_is_true
    assert_equal true, @config.disable_web_page_preview
  end

  def test_defaults_message_prefix_is_nil
    assert_nil @config.message_prefix
  end

  def test_defaults_message_suffix_is_nil
    assert_nil @config.message_suffix
  end

  def test_defaults_formatting_options
    assert_equal true, @config.formatting_options[:escape_markdown]
    assert_equal false, @config.formatting_options[:obfuscate_emails]
    assert_equal false, @config.formatting_options[:escape_html]
    assert_equal 4096, @config.formatting_options[:truncate]
  end

  def test_defaults_client_options
    assert_equal 30, @config.client_options[:timeout]
    assert_equal 3, @config.client_options[:retry_count]
    assert_equal 1, @config.client_options[:retry_delay]
  end

  def test_defaults_deliver_message_async_is_false
    assert_equal false, @config.deliver_message_async
  end

  def test_defaults_deliver_message_queue_is_default
    assert_equal "default", @config.deliver_message_queue
  end

  # ===========================================================================
  # Setter Tests
  # ===========================================================================

  def test_can_set_bot_token
    @config.bot_token = "123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11"
    assert_equal "123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11", @config.bot_token
  end

  def test_can_set_chat_id_as_integer
    @config.chat_id = 123456789
    assert_equal 123456789, @config.chat_id
  end

  def test_can_set_chat_id_as_string
    @config.chat_id = "@my_channel"
    assert_equal "@my_channel", @config.chat_id
  end

  def test_can_set_chat_id_as_negative_for_groups
    @config.chat_id = -1001234567890
    assert_equal(-1001234567890, @config.chat_id)
  end

  def test_can_set_parse_mode_to_html
    @config.default_parse_mode = "HTML"
    assert_equal "HTML", @config.default_parse_mode
  end

  def test_can_set_parse_mode_to_nil
    @config.default_parse_mode = nil
    assert_nil @config.default_parse_mode
  end

  def test_can_set_message_prefix
    @config.message_prefix = "[Production] "
    assert_equal "[Production] ", @config.message_prefix
  end

  def test_can_set_message_suffix
    @config.message_suffix = "\n--\nSent from MyApp"
    assert_equal "\n--\nSent from MyApp", @config.message_suffix
  end

  def test_can_set_formatting_options
    @config.formatting_options = {
      escape_markdown: false,
      obfuscate_emails: true,
      escape_html: true,
      truncate: 1000
    }
    assert_equal false, @config.formatting_options[:escape_markdown]
    assert_equal true, @config.formatting_options[:obfuscate_emails]
    assert_equal true, @config.formatting_options[:escape_html]
    assert_equal 1000, @config.formatting_options[:truncate]
  end

  def test_can_set_client_options
    @config.client_options = { timeout: 60, retry_count: 5, retry_delay: 2 }
    assert_equal 60, @config.client_options[:timeout]
    assert_equal 5, @config.client_options[:retry_count]
    assert_equal 2, @config.client_options[:retry_delay]
  end

  def test_can_set_deliver_message_async
    @config.deliver_message_async = true
    assert_equal true, @config.deliver_message_async
  end

  def test_can_set_deliver_message_queue
    @config.deliver_message_queue = "critical"
    assert_equal "critical", @config.deliver_message_queue
  end

  # ===========================================================================
  # Validation: bot_token Tests
  # ===========================================================================

  def test_validate_raises_error_when_bot_token_is_nil
    @config.bot_token = nil
    error = assert_raises(ArgumentError) { @config.validate! }
    assert_includes error.message, "bot_token cannot be blank"
  end

  def test_validate_raises_error_when_bot_token_is_empty_string
    @config.bot_token = ""
    error = assert_raises(ArgumentError) { @config.validate! }
    assert_includes error.message, "bot_token cannot be blank"
  end

  def test_validate_raises_error_when_bot_token_is_whitespace_only
    @config.bot_token = "   "
    error = assert_raises(ArgumentError) { @config.validate! }
    assert_includes error.message, "bot_token cannot be blank"
  end

  def test_validate_raises_error_when_bot_token_is_tabs_and_newlines
    @config.bot_token = "\t\n\r"
    error = assert_raises(ArgumentError) { @config.validate! }
    assert_includes error.message, "bot_token cannot be blank"
  end

  def test_validate_passes_with_valid_bot_token
    @config.bot_token = "123456:ABC-DEF"
    assert @config.validate!
  end

  # ===========================================================================
  # Validation: default_parse_mode Tests
  # ===========================================================================

  def test_validate_passes_with_markdownv2_parse_mode
    @config.bot_token = "token"
    @config.default_parse_mode = "MarkdownV2"
    assert @config.validate!
  end

  def test_validate_passes_with_html_parse_mode
    @config.bot_token = "token"
    @config.default_parse_mode = "HTML"
    assert @config.validate!
  end

  def test_validate_passes_with_nil_parse_mode
    @config.bot_token = "token"
    @config.default_parse_mode = nil
    assert @config.validate!
  end

  def test_validate_raises_error_with_invalid_parse_mode
    @config.bot_token = "token"
    @config.default_parse_mode = "Markdown"  # Old Markdown (not MarkdownV2)
    error = assert_raises(ArgumentError) { @config.validate! }
    assert_includes error.message, "default_parse_mode"
  end

  def test_validate_raises_error_with_random_parse_mode
    @config.bot_token = "token"
    @config.default_parse_mode = "XML"
    error = assert_raises(ArgumentError) { @config.validate! }
    assert_includes error.message, "default_parse_mode"
  end

  def test_validate_raises_error_with_lowercase_parse_mode
    @config.bot_token = "token"
    @config.default_parse_mode = "html"  # Should be "HTML"
    error = assert_raises(ArgumentError) { @config.validate! }
    assert_includes error.message, "default_parse_mode"
  end

  # ===========================================================================
  # Validation: formatting_options Tests
  # ===========================================================================

  def test_validate_raises_error_when_formatting_options_is_not_hash
    @config.bot_token = "token"
    @config.formatting_options = "not a hash"
    error = assert_raises(ArgumentError) { @config.validate! }
    assert_includes error.message, "formatting_options must be a hash"
  end

  def test_validate_raises_error_when_formatting_options_is_array
    @config.bot_token = "token"
    @config.formatting_options = [1, 2, 3]
    error = assert_raises(ArgumentError) { @config.validate! }
    assert_includes error.message, "formatting_options must be a hash"
  end

  def test_validate_raises_error_when_escape_markdown_is_string
    @config.bot_token = "token"
    @config.formatting_options = { escape_markdown: "yes" }
    error = assert_raises(ArgumentError) { @config.validate! }
    assert_includes error.message, "escape_markdown"
    assert_includes error.message, "true or false"
  end

  def test_validate_raises_error_when_obfuscate_emails_is_string
    @config.bot_token = "token"
    @config.formatting_options = { obfuscate_emails: "true" }
    error = assert_raises(ArgumentError) { @config.validate! }
    assert_includes error.message, "obfuscate_emails"
  end

  def test_validate_raises_error_when_escape_html_is_integer
    @config.bot_token = "token"
    @config.formatting_options = { escape_html: 1 }
    error = assert_raises(ArgumentError) { @config.validate! }
    assert_includes error.message, "escape_html"
  end

  def test_validate_raises_error_when_truncate_is_zero
    @config.bot_token = "token"
    @config.formatting_options = { truncate: 0 }
    error = assert_raises(ArgumentError) { @config.validate! }
    assert_includes error.message, "truncate"
  end

  def test_validate_raises_error_when_truncate_is_negative
    @config.bot_token = "token"
    @config.formatting_options = { truncate: -100 }
    error = assert_raises(ArgumentError) { @config.validate! }
    assert_includes error.message, "truncate"
  end

  def test_validate_raises_error_when_truncate_is_string
    @config.bot_token = "token"
    @config.formatting_options = { truncate: "4096" }
    error = assert_raises(ArgumentError) { @config.validate! }
    assert_includes error.message, "truncate"
  end

  def test_validate_raises_error_when_truncate_is_float
    @config.bot_token = "token"
    @config.formatting_options = { truncate: 100.5 }
    error = assert_raises(ArgumentError) { @config.validate! }
    assert_includes error.message, "truncate"
  end

  def test_validate_passes_with_valid_formatting_options
    @config.bot_token = "token"
    @config.formatting_options = {
      escape_markdown: true,
      obfuscate_emails: false,
      escape_html: true,
      truncate: 1000
    }
    assert @config.validate!
  end

  def test_validate_passes_with_partial_formatting_options
    @config.bot_token = "token"
    @config.formatting_options = { truncate: 500 }  # Only truncate specified
    assert @config.validate!
  end

  def test_validate_passes_with_empty_formatting_options_hash
    @config.bot_token = "token"
    @config.formatting_options = {}
    assert @config.validate!
  end

  # ===========================================================================
  # Validation: client_options Tests
  # ===========================================================================

  def test_validate_raises_error_when_client_options_is_not_hash
    @config.bot_token = "token"
    @config.client_options = "not a hash"
    error = assert_raises(ArgumentError) { @config.validate! }
    assert_includes error.message, "client_options must be a hash"
  end

  def test_validate_raises_error_when_timeout_is_string
    @config.bot_token = "token"
    @config.client_options = { timeout: "30" }
    error = assert_raises(ArgumentError) { @config.validate! }
    assert_includes error.message, "timeout"
  end

  def test_validate_raises_error_when_timeout_is_zero
    @config.bot_token = "token"
    @config.client_options = { timeout: 0 }
    error = assert_raises(ArgumentError) { @config.validate! }
    assert_includes error.message, "timeout"
  end

  def test_validate_raises_error_when_timeout_is_negative
    @config.bot_token = "token"
    @config.client_options = { timeout: -10 }
    error = assert_raises(ArgumentError) { @config.validate! }
    assert_includes error.message, "timeout"
  end

  def test_validate_raises_error_when_timeout_is_float
    @config.bot_token = "token"
    @config.client_options = { timeout: 30.5 }
    error = assert_raises(ArgumentError) { @config.validate! }
    assert_includes error.message, "timeout"
  end

  def test_validate_raises_error_when_retry_count_is_string
    @config.bot_token = "token"
    @config.client_options = { retry_count: "3" }
    error = assert_raises(ArgumentError) { @config.validate! }
    assert_includes error.message, "retry_count"
  end

  def test_validate_raises_error_when_retry_count_is_negative
    @config.bot_token = "token"
    @config.client_options = { retry_count: -1 }
    error = assert_raises(ArgumentError) { @config.validate! }
    assert_includes error.message, "retry_count"
  end

  def test_validate_raises_error_when_retry_delay_is_string
    @config.bot_token = "token"
    @config.client_options = { retry_delay: "1" }
    error = assert_raises(ArgumentError) { @config.validate! }
    assert_includes error.message, "retry_delay"
  end

  def test_validate_raises_error_when_retry_delay_is_negative
    @config.bot_token = "token"
    @config.client_options = { retry_delay: -1 }
    error = assert_raises(ArgumentError) { @config.validate! }
    assert_includes error.message, "retry_delay"
  end

  def test_validate_raises_error_when_retry_delay_is_zero
    @config.bot_token = "token"
    @config.client_options = { retry_delay: 0 }
    error = assert_raises(ArgumentError) { @config.validate! }
    assert_includes error.message, "retry_delay"
  end

  def test_validate_passes_with_retry_delay_as_float
    # README shows examples with retry_delay: 0.5
    @config.bot_token = "token"
    @config.client_options = { timeout: 30, retry_count: 3, retry_delay: 0.5 }
    assert @config.validate!
  end

  def test_validate_passes_with_valid_client_options
    @config.bot_token = "token"
    @config.client_options = { timeout: 60, retry_count: 5, retry_delay: 2 }
    assert @config.validate!
  end

  def test_validate_passes_with_partial_client_options
    @config.bot_token = "token"
    @config.client_options = { timeout: 60 }  # Only timeout specified
    assert @config.validate!
  end

  def test_validate_passes_with_empty_client_options_hash
    @config.bot_token = "token"
    @config.client_options = {}
    assert @config.validate!
  end

  # ===========================================================================
  # Full Configuration Validation Tests
  # ===========================================================================

  def test_validate_returns_true_when_all_valid
    @config.bot_token = "valid_token"
    @config.chat_id = 123456
    @config.default_parse_mode = "MarkdownV2"
    @config.formatting_options = { escape_markdown: true, truncate: 4096 }
    @config.client_options = { timeout: 30, retry_count: 3, retry_delay: 1 }

    assert_equal true, @config.validate!
  end

  def test_validate_checks_all_validations_in_sequence
    @config.bot_token = nil  # This should fail first
    @config.default_parse_mode = "invalid"  # This would fail second
    @config.formatting_options = "not a hash"  # This would fail third

    error = assert_raises(ArgumentError) { @config.validate! }
    assert_includes error.message, "bot_token"  # First error encountered
  end

  # ===========================================================================
  # Edge Cases and Special Values
  # ===========================================================================

  def test_can_set_very_long_bot_token
    long_token = "a" * 1000
    @config.bot_token = long_token
    assert_equal long_token, @config.bot_token
  end

  def test_can_set_unicode_in_prefix
    @config.message_prefix = "[🚀 Production] "
    assert_equal "[🚀 Production] ", @config.message_prefix
  end

  def test_can_set_multiline_suffix
    suffix = <<~SUFFIX
      --
      Sent from MyApp
      Environment: Production
    SUFFIX
    @config.message_suffix = suffix
    assert_equal suffix, @config.message_suffix
  end

  def test_formatting_options_can_have_extra_keys
    @config.bot_token = "token"
    @config.formatting_options = {
      escape_markdown: true,
      custom_option: "value",  # Extra key should be ignored in validation
      truncate: 100
    }
    assert @config.validate!
  end

  def test_client_options_can_have_extra_keys
    @config.bot_token = "token"
    @config.client_options = {
      timeout: 30,
      custom_option: "value"  # Extra key should be ignored in validation
    }
    assert @config.validate!
  end

  def test_validate_is_idempotent
    @config.bot_token = "token"

    # Call validate! multiple times
    assert @config.validate!
    assert @config.validate!
    assert @config.validate!
  end

  def test_configuration_can_be_modified_after_validation
    @config.bot_token = "token"
    @config.validate!

    # Should be able to modify and re-validate
    @config.chat_id = 999
    @config.validate!

    assert_equal 999, @config.chat_id
  end
end
