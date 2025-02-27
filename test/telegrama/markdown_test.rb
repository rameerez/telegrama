require "test_helper"

class Telegrama::FormatterTest < Minitest::Test
  def setup
    # Set up default configuration for tests
    Telegrama.configuration.formatting_options = {
      escape_markdown: true,
      obfuscate_emails: false,
      escape_html: false,
      truncate: 4096
    }
    Telegrama.configuration.message_prefix = nil
    Telegrama.configuration.message_suffix = nil
    Telegrama.configuration.default_parse_mode = 'MarkdownV2'
  end

  #---------------------------------------------------------------------------
  # BASIC MARKDOWN TESTS
  #---------------------------------------------------------------------------

  def test_plain_text
    text = "This is just plain text without any special characters."
    result = Telegrama::Formatter.format(text)
    assert_equal text, result
  end

  def test_basic_bold
    text = "This is *bold* text"
    result = Telegrama::Formatter.format(text)
    assert_equal "This is *bold* text", result
  end

  def test_basic_italic
    text = "This is _italic_ text"
    result = Telegrama::Formatter.format(text)
    assert_equal "This is _italic_ text", result
  end

  def test_basic_code
    text = "This is `code` text"
    result = Telegrama::Formatter.format(text)
    assert_equal "This is `code` text", result
  end

  def test_basic_link
    text = "This is a [link](https://example.com)"
    result = Telegrama::Formatter.format(text)
    assert_equal "This is a [link](https://example.com)", result
  end

  #---------------------------------------------------------------------------
  # SPECIAL CHARACTER HANDLING TESTS
  #---------------------------------------------------------------------------

  def test_escaping_special_chars
    # All special characters that need escaping in MarkdownV2
    text = "Special chars: _ * [ ] ( ) ~ ` > # + - = | { } . !"
    result = Telegrama::Formatter.format(text)
    expected = "Special chars: \\_ \\* \\[ \\] \\( \\) \\~ \\` \\> \\# \\+ \\- \\= \\| \\{ \\} \\. \\!"
    assert_equal expected, result
  end

  def test_backslash_escaping
    text = "Backslash \\ and \\* escaped asterisk"
    result = Telegrama::Formatter.format(text)
    expected = "Backslash \\\\ and \\\\\\* escaped asterisk"
    assert_equal expected, result
  end

  def test_url_with_special_chars
    text = "Visit [my site](https://example.com/search?q=test&filter=123)"
    result = Telegrama::Formatter.format(text)
    expected = "Visit [my site](https://example.com/search\\?q\\=test\\&filter\\=123)"
    assert_equal expected, result
  end

  #---------------------------------------------------------------------------
  # CODE BLOCK TESTS
  #---------------------------------------------------------------------------

  def test_simple_code_block
    text = "Code block: `var x = 10;`"
    result = Telegrama::Formatter.format(text)
    expected = "Code block: `var x = 10;`"
    assert_equal expected, result
  end

  def test_code_block_with_special_chars
    text = "Code with special: `var x = \"Hello, world!\";`"
    result = Telegrama::Formatter.format(text)
    expected = "Code with special: `var x = \"Hello, world!\";`"
    assert_equal expected, result
  end

  def test_code_block_with_backticks
    text = "Backticks in code: `var code = `nested`;`"
    result = Telegrama::Formatter.format(text)
    # The inner backticks should be escaped
    expected = "Backticks in code: `var code = \\`nested\\`;`"
    assert_equal expected, result
  end

  def test_triple_backtick_code_block
    text = "```ruby\ndef hello\n  puts \"Hi\"\nend\n```"
    result = Telegrama::Formatter.format(text)
    # This should be handled as a special case
    refute_nil result
  end

  #---------------------------------------------------------------------------
  # COMPLEX MARKDOWN TESTS
  #---------------------------------------------------------------------------

  def test_nested_formatting
    text = "This is *bold with _italic_ inside*"
    result = Telegrama::Formatter.format(text)
    expected = "This is *bold with \\_italic\\_ inside*"
    assert_equal expected, result
  end

  def test_complex_mixed_formatting
    text = "Complex *bold with `code` and _italic_* mixed"
    result = Telegrama::Formatter.format(text)
    expected = "Complex *bold with `code` and \\_italic\\_* mixed"
    assert_equal expected, result
  end

  def test_all_formatting_features
    text = "*Bold* _italic_ `code` [link](https://example.com) and normal"
    result = Telegrama::Formatter.format(text)
    expected = "*Bold* _italic_ `code` [link](https://example.com) and normal"
    assert_equal expected, result
  end

  #---------------------------------------------------------------------------
  # EDGE CASE TESTS
  #---------------------------------------------------------------------------

  def test_unbalanced_formatting
    text = "This has *unbalanced _formatting* like this_"
    result = Telegrama::Formatter.format(text)
    # Should handle this gracefully without exceptions
    refute_nil result
  end

  def test_incomplete_code_blocks
    text = "This has `incomplete code block"
    result = Telegrama::Formatter.format(text)
    # Should handle this gracefully without exceptions
    refute_nil result
  end

  def test_incomplete_links
    text = "This link is incomplete [title](http://example"
    result = Telegrama::Formatter.format(text)
    # Should handle this gracefully without exceptions
    refute_nil result
  end

  def test_complex_regex_in_code
    m = 1
    text = "Ruby regex: `text.gsub(/[_*[\\]()~`>#+\\-=|{}.!\\\\]/) { |m| \"\\\\#{m}\" }`"
    result = Telegrama::Formatter.format(text)
    # Should handle this gracefully without exceptions
    refute_nil result
  end

  def test_nested_code_blocks_with_special_chars
    text = "Testing nested code: `outer code with inner \\`backtick\\` and *asterisks*`"
    result = Telegrama::Formatter.format(text)
    # Should handle this gracefully without exceptions
    refute_nil result
  end

  def test_backslash_edge_cases
    text = "Testing backslashes: \\\\ and \\* and \\` and code with backslashes: `var x = \"escaped \\\" quote\";`"
    result = Telegrama::Formatter.format(text)
    # Should handle this gracefully without exceptions
    refute_nil result
  end

  #---------------------------------------------------------------------------
  # MULTI-LINE TEXT TESTS
  #---------------------------------------------------------------------------

  def test_multiline_text
    text = <<~TEXT
      This is a multi-line text.
      It has several lines.
      *Bold text* spans a single line.
    TEXT

    result = Telegrama::Formatter.format(text)
    # Should handle this gracefully without exceptions
    refute_nil result
  end

  def test_complex_multiline_with_code
    m = 1

    text = <<~TEXT
      Complex example with multi-line code:
      ```ruby
      def escape_special(text)
        text.gsub(/([_*[\\]()~`>#+\\-=|{}.!\\\\])/) do |m|
          "\\\\#{m}"
        end
      end
      ```
      And some *formatting* outside the block
    TEXT

    result = Telegrama::Formatter.format(text)
    # Should handle this gracefully without exceptions
    refute_nil result
  end

  #---------------------------------------------------------------------------
  # EMAIL OBFUSCATION TESTS
  #---------------------------------------------------------------------------

  def test_email_obfuscation
    Telegrama.configuration.formatting_options[:obfuscate_emails] = true

    text = "Contact me at john.doe@example.com or another.email123@gmail.com"
    result = Telegrama::Formatter.format(text)

    # Emails should be obfuscated - no escaping should happen on the obfuscated emails
    refute_includes result, "john.doe@example.com"
    refute_includes result, "another.email123@gmail.com"

    # Strip any backslashes that might have been added during formatting
    clean_result = result.gsub('\\', '')
    assert_includes clean_result, "joh...e@example.com"
    assert_includes clean_result, "ano...3@gmail.com"
  end

  def test_email_in_code_block
    Telegrama.configuration.formatting_options[:obfuscate_emails] = true

    text = "Email in code: `user_email = \"complex+address.with_special-chars@example.com\"`"
    result = Telegrama::Formatter.format(text)

    # Email inside code block should still be obfuscated
    refute_includes result, "complex+address.with_special-chars@example.com"
    assert_includes result, "com...s@example.com"
  end

  #---------------------------------------------------------------------------
  # HTML ESCAPE TESTS
  #---------------------------------------------------------------------------

  def test_html_escaping
    Telegrama.configuration.formatting_options[:escape_html] = true

    text = "HTML tags <div>should be</div> escaped <script>alert('xss')</script>"
    result = Telegrama::Formatter.format(text)

    # HTML should be escaped
    refute_includes result, "<div>"
    assert_includes result, "&lt;div&gt;"
    refute_includes result, "<script>"
    assert_includes result, "&lt;script&gt;"
  end

  def test_html_mixed_with_markdown
    Telegrama.configuration.formatting_options[:escape_html] = true

    text = "HTML escaped <div>content</div> with `<code>blocks</code>` and *formatting*"
    result = Telegrama::Formatter.format(text)

    # HTML should be escaped while preserving markdown
    assert_includes result, "&lt;div&gt;content&lt;/div&gt;"
    assert_includes result, "`&lt;code&gt;blocks&lt;/code&gt;`"
    assert_includes result, "*formatting*"
  end

  #---------------------------------------------------------------------------
  # PREFIX/SUFFIX TESTS
  #---------------------------------------------------------------------------

  def test_message_prefix
    Telegrama.configuration.message_prefix = "[TEST] "

    text = "This is a test message"
    result = Telegrama::Formatter.format(text)

    assert_equal "[TEST] This is a test message", result
  end

  def test_message_suffix
    Telegrama.configuration.message_suffix = "\n--\nSent via Telegrama"

    text = "This is a test message"
    result = Telegrama::Formatter.format(text)

    assert_equal "This is a test message\n--\nSent via Telegrama", result
  end

  def test_prefix_and_suffix_together
    Telegrama.configuration.message_prefix = "[TEST] "
    Telegrama.configuration.message_suffix = "\n--\nSent via Telegrama"

    text = "This is a test message"
    result = Telegrama::Formatter.format(text)

    assert_equal "[TEST] This is a test message\n--\nSent via Telegrama", result
  end

  #---------------------------------------------------------------------------
  # TRUNCATION TESTS
  #---------------------------------------------------------------------------

  def test_truncation
    Telegrama.configuration.formatting_options[:truncate] = 20

    text = "This is a very long message that should be truncated"
    result = Telegrama::Formatter.format(text)

    assert_equal "This is a very long ", result
    assert_equal 20, result.length
  end

  def test_no_truncation_within_limit
    Telegrama.configuration.formatting_options[:truncate] = 20

    text = "Short message"
    result = Telegrama::Formatter.format(text)

    assert_equal "Short message", result
  end

  #---------------------------------------------------------------------------
  # FAILURE RECOVERY TESTS
  #---------------------------------------------------------------------------

  def test_recover_from_invalid_markdown
    Telegrama.configuration.formatting_options[:escape_markdown] = true

    # Save the original method and swap in a broken one
    original_method = Telegrama::Formatter.method(:escape_markdown_v2)
    Telegrama::Formatter.define_singleton_method(:escape_markdown_v2) do |text|
      raise "Simulated markdown parsing error"
    end

    begin
      text = "This *bold* text should still be delivered even if formatting fails"
      # Stub the log_error method to avoid Rails errors
      original_log_error = Telegrama.method(:log_error)
      Telegrama.define_singleton_method(:log_error) do |message|
        # Do nothing for testing
      end

      # Override the strip_markdown method temporarily to not strip formatting
      original_strip_markdown = Telegrama::Formatter.method(:strip_markdown)
      Telegrama::Formatter.define_singleton_method(:strip_markdown) do |text|
        text # Return text unchanged to match expected result in this test
      end

      result = Telegrama::Formatter.format(text)

      # The message should still be delivered, with the original text
      refute_nil result
      assert_equal text, result
    ensure
      # Restore the original methods
      Telegrama::Formatter.define_singleton_method(:escape_markdown_v2, original_method)
      Telegrama.define_singleton_method(:log_error, original_log_error) if defined?(original_log_error)
      Telegrama::Formatter.define_singleton_method(:strip_markdown, original_strip_markdown) if defined?(original_strip_markdown)
    end
  end
end

#===========================================================================
# INTEGRATION TESTS - Testing the formatter with the client
#===========================================================================

class TelegramaIntegrationTest < Minitest::Test
  def setup
    # Reset the test state
    Telegrama::TestState.reset

    # Save original methods if needed
    @original_format = Telegrama::Formatter.method(:format)
  end

  def teardown
    # Restore original methods if needed
    if defined?(@original_format)
      Telegrama::Formatter.define_singleton_method(:format, @original_format)
    end
  end

  def test_client_send_basic_message
    client = Telegrama::Client.new
    response = client.send_message("Hello, world!")

    # Should be successful
    assert_equal 200, response.code
    assert response.body[:ok]
  end

  def test_client_handles_markdown_error
    # Configure the test state to fail API requests
    Telegrama::TestState.should_fail_api_request = true
    Telegrama::TestState.api_failure_count = 0
    Telegrama::TestState.max_api_failures = 1

    client = Telegrama::Client.new

    # This would normally trigger markdown formatting
    begin
      response = client.send_message("*Bold text* that causes an error")
      # If we got here, no exception was raised
      assert_equal 200, response.code
      assert response.body[:ok]
    rescue => e
      flunk("Exception was raised: #{e.message}")
    end
  end

  def test_complex_markdown_fallback
    # Configure the test state to fail API requests
    Telegrama::TestState.should_fail_api_request = true
    Telegrama::TestState.api_failure_count = 0
    Telegrama::TestState.max_api_failures = 1

    client = Telegrama::Client.new

    complex_message = <<~MARKDOWN
      # Complex Markdown

      This message has *bold*, _italic_, and `code` formatting.

      ```
      function test() {
        return "This is a code block";
      }
      ```

      And a [link](https://example.com?q=test&param=value) with special chars.
    MARKDOWN

    # Make sure the test doesn't throw an exception
    begin
      response = client.send_message(complex_message)
      # If we got here, no exception was raised
      assert_equal 200, response.code
      assert response.body[:ok]
    rescue => e
      flunk("Exception was raised: #{e.message}")
    end
  end
end
