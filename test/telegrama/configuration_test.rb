require "test_helper"

class Telegrama::ConfigurationTest < Minitest::Test
  def setup
    # fresh configuration instance for isolation
    Telegrama.instance_variable_set(:@configuration, Telegrama::Configuration.new)
  end

  def test_defaults
    cfg = Telegrama.configuration
    assert_nil cfg.bot_token
    assert_nil cfg.chat_id
    assert_equal 'MarkdownV2', cfg.default_parse_mode
    assert_equal true, cfg.disable_web_page_preview
    assert_nil cfg.message_prefix
    assert_nil cfg.message_suffix

    assert_equal true, cfg.formatting_options[:escape_markdown]
    assert_equal false, cfg.formatting_options[:obfuscate_emails]
    assert_equal false, cfg.formatting_options[:escape_html]
    assert_equal 4096, cfg.formatting_options[:truncate]

    assert_equal 30, cfg.client_options[:timeout]
    assert_equal 3, cfg.client_options[:retry_count]
    assert_equal 1, cfg.client_options[:retry_delay]

    assert_equal false, cfg.deliver_message_async
    assert_equal 'default', cfg.deliver_message_queue
  end

  def test_validate_requires_bot_token
    cfg = Telegrama.configuration
    cfg.bot_token = nil
    error = assert_raises(ArgumentError) { cfg.validate! }
    assert_includes error.message, 'bot_token cannot be blank'

    cfg.bot_token = '  '
    error = assert_raises(ArgumentError) { cfg.validate! }
    assert_includes error.message, 'bot_token cannot be blank'

    cfg.bot_token = 'abc'
    # should now validate when other settings are valid
    cfg.default_parse_mode = 'MarkdownV2'
    cfg.formatting_options = { escape_markdown: true, obfuscate_emails: false, escape_html: false, truncate: 10 }
    cfg.client_options = { timeout: 10, retry_count: 1, retry_delay: 1 }
    assert cfg.validate!
  end

  def test_validate_default_parse_mode
    cfg = Telegrama.configuration
    cfg.bot_token = 't'

    cfg.default_parse_mode = 'MarkdownV2'
    assert cfg.validate!

    cfg.default_parse_mode = 'HTML'
    assert cfg.validate!

    cfg.default_parse_mode = nil
    assert cfg.validate!

    cfg.default_parse_mode = 'PLAINTEXT'
    error = assert_raises(ArgumentError) { cfg.validate! }
    assert_includes error.message, 'default_parse_mode'
  end

  def test_validate_formatting_options_types
    cfg = Telegrama.configuration
    cfg.bot_token = 't'

    cfg.formatting_options = { escape_markdown: 'yes' }
    error = assert_raises(ArgumentError) { cfg.validate! }
    assert_includes error.message, 'escape_markdown'

    cfg.formatting_options = { escape_markdown: true, truncate: 0 }
    error = assert_raises(ArgumentError) { cfg.validate! }
    assert_includes error.message, 'truncate'

    cfg.formatting_options = { escape_markdown: true, truncate: 10, obfuscate_emails: false, escape_html: false }
    cfg.default_parse_mode = 'MarkdownV2'
    assert cfg.validate!
  end

  def test_validate_client_options_types
    cfg = Telegrama.configuration
    cfg.bot_token = 't'

    cfg.client_options = { timeout: '10' }
    error = assert_raises(ArgumentError) { cfg.validate! }
    assert_includes error.message, 'timeout'

    cfg.client_options = { timeout: 10, retry_count: -1 }
    error = assert_raises(ArgumentError) { cfg.validate! }
    assert_includes error.message, 'retry_count'

    cfg.client_options = { timeout: 10, retry_count: 2, retry_delay: 1 }
    assert cfg.validate!
  end
end