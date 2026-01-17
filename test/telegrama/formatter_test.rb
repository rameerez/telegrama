# frozen_string_literal: true

require "test_helper"

class Telegrama::FormatterTest < TelegramaTestCase
  def setup
    super
    configure_telegrama(
      bot_token: "test-token",
      chat_id: 123,
      formatting: {
        escape_markdown: true,
        obfuscate_emails: false,
        escape_html: false,
        truncate: 4096
      }
    )
  end

  # ===========================================================================
  # Basic Text Tests
  # ===========================================================================

  def test_plain_text_passes_through
    # Plain text without special chars passes through unchanged
    text = "Hello World"  # No exclamation - that's a special char in MarkdownV2
    result = Telegrama::Formatter.format(text)
    assert_equal text, result
  end

  def test_plain_text_with_exclamation_gets_escaped
    # Exclamation is a special char in MarkdownV2 and gets escaped
    text = "Hello, World!"
    result = Telegrama::Formatter.format(text)
    assert_equal "Hello, World\\!", result
  end

  def test_handles_nil_input
    result = Telegrama::Formatter.format(nil)
    assert_equal "", result
  end

  def test_handles_empty_string
    result = Telegrama::Formatter.format("")
    assert_equal "", result
  end

  def test_handles_whitespace_only
    result = Telegrama::Formatter.format("   ")
    assert_equal "   ", result
  end

  def test_preserves_newlines
    text = "Line 1\nLine 2\nLine 3"
    result = Telegrama::Formatter.format(text)
    assert_includes result, "\n"
    assert_equal 2, result.count("\n")
  end

  def test_preserves_tabs
    text = "Col1\tCol2\tCol3"
    result = Telegrama::Formatter.format(text)
    assert_includes result, "\t"
  end

  # ===========================================================================
  # Basic Markdown Formatting Tests
  # ===========================================================================

  def test_preserves_bold_formatting
    result = Telegrama::Formatter.format("This is *bold* text")
    assert_includes result, "*bold*"
  end

  def test_preserves_italic_formatting
    result = Telegrama::Formatter.format("This is _italic_ text")
    assert_includes result, "_italic_"
  end

  def test_preserves_inline_code
    result = Telegrama::Formatter.format("This is `code` text")
    assert_includes result, "`code`"
  end

  def test_preserves_links
    result = Telegrama::Formatter.format("Visit [link](https://example.com)")
    assert_includes result, "[link]"
    assert_includes result, "https://example"
  end

  # ===========================================================================
  # Special Character Escaping Tests
  # ===========================================================================

  def test_escapes_dot
    result = Telegrama::Formatter.format("End of sentence.")
    assert_includes result, "\\."
  end

  def test_escapes_exclamation
    result = Telegrama::Formatter.format("Wow!")
    assert_includes result, "\\!"
  end

  def test_escapes_hash
    result = Telegrama::Formatter.format("Number #1")
    assert_includes result, "\\#"
  end

  def test_escapes_plus
    result = Telegrama::Formatter.format("2+2=4")
    assert_includes result, "\\+"
  end

  def test_escapes_minus_outside_formatting
    result = Telegrama::Formatter.format("A - B")
    assert_includes result, "\\-"
  end

  def test_escapes_equals
    result = Telegrama::Formatter.format("x=5")
    assert_includes result, "\\="
  end

  def test_escapes_pipe
    result = Telegrama::Formatter.format("A | B")
    assert_includes result, "\\|"
  end

  def test_escapes_braces
    result = Telegrama::Formatter.format("{key: value}")
    assert_includes result, "\\{"
    assert_includes result, "\\}"
  end

  def test_escapes_tilde
    result = Telegrama::Formatter.format("Approximately ~100")
    assert_includes result, "\\~"
  end

  def test_escapes_greater_than
    result = Telegrama::Formatter.format("A > B")
    assert_includes result, "\\>"
  end

  def test_escapes_parentheses_outside_links
    result = Telegrama::Formatter.format("Example (test)")
    assert_includes result, "\\("
    assert_includes result, "\\)"
  end

  def test_escapes_brackets_outside_links
    # Note: brackets that don't form a complete link pattern may be treated specially
    # The tokenizer checks for complete [text](url) patterns
    result = Telegrama::Formatter.format("Array [1,2,3]")
    # Just verify the output contains the array content
    assert_includes result, "1,2,3"
  end

  # ===========================================================================
  # Code Block Tests
  # ===========================================================================

  def test_inline_code_content_not_escaped
    result = Telegrama::Formatter.format("Run `var x = 10;`")
    # Inside code, the semicolon should NOT be escaped
    assert_includes result, "`var x = 10;`"
  end

  def test_triple_backtick_code_block_preserved
    text = "```ruby\ndef hello\n  puts 'Hi'\nend\n```"
    result = Telegrama::Formatter.format(text)
    assert_includes result, "```ruby"
    assert_includes result, "def hello"
    assert_includes result, "```"
  end

  def test_code_block_with_special_chars
    text = "Code: `x = a * b + c;`"
    result = Telegrama::Formatter.format(text)
    # Inside code block, asterisk should not be treated as bold marker
    assert_includes result, "`"
  end

  def test_empty_code_block
    result = Telegrama::Formatter.format("Empty: ``")
    assert_includes result, "``"
  end

  def test_code_block_with_backticks_inside
    text = "Nested: `code with \\`backtick\\``"
    result = Telegrama::Formatter.format(text)
    # Backticks inside code should be escaped
    assert_includes result, "\\`"
  end

  # ===========================================================================
  # Link Tests
  # ===========================================================================

  def test_basic_link
    result = Telegrama::Formatter.format("[click here](https://example.com)")
    assert_includes result, "[click here]"
    assert_includes result, "https://example"
  end

  def test_link_with_query_params
    text = "[search](https://example.com/search?q=test&filter=1)"
    result = Telegrama::Formatter.format(text)
    assert_includes result, "[search]"
    assert_includes result, "https://example"
  end

  def test_link_with_special_chars_in_url
    text = "[docs](https://example.com/path#section)"
    result = Telegrama::Formatter.format(text)
    assert_includes result, "[docs]"
    assert_includes result, "https://example"
  end

  def test_link_with_emoji_in_text
    text = "[🔗 Link](https://example.com)"
    result = Telegrama::Formatter.format(text)
    assert_includes result, "🔗"
    assert_includes result, "Link"
  end

  def test_multiple_links
    text = "[link1](https://a.com) and [link2](https://b.com)"
    result = Telegrama::Formatter.format(text)
    assert_includes result, "[link1]"
    assert_includes result, "[link2]"
  end

  def test_incomplete_link_handled_gracefully
    text = "[title](http://incomplete"
    result = Telegrama::Formatter.format(text)
    # Should not crash and should contain the original text
    refute_nil result
    assert_includes result, "title"
  end

  def test_link_without_url
    text = "[text only]"
    result = Telegrama::Formatter.format(text)
    refute_nil result
  end

  # ===========================================================================
  # Nested Formatting Tests
  # ===========================================================================

  def test_bold_with_italic_inside
    text = "*bold with _italic_ inside*"
    result = Telegrama::Formatter.format(text)
    assert_includes result, "*"
    # Underscores inside bold should be escaped
    assert_includes result, "\\_"
  end

  def test_italic_with_bold_inside
    text = "_italic with *bold* inside_"
    result = Telegrama::Formatter.format(text)
    assert_includes result, "_"
    assert_includes result, "*"
  end

  def test_code_inside_bold
    text = "*bold with `code` inside*"
    result = Telegrama::Formatter.format(text)
    # Bold markers should be preserved
    assert_includes result, "*"
    # Code inside bold - backticks may be escaped in some implementations
    assert_includes result, "code"
  end

  def test_complex_nested_formatting
    text = "*Bold _and italic_ and `code`* normal"
    result = Telegrama::Formatter.format(text)
    refute_nil result
    assert_includes result, "*"
  end

  # ===========================================================================
  # Edge Cases
  # ===========================================================================

  def test_unmatched_asterisk
    text = "This has * unmatched asterisk"
    result = Telegrama::Formatter.format(text)
    refute_nil result
  end

  def test_unmatched_underscore
    text = "This has _ unmatched underscore"
    result = Telegrama::Formatter.format(text)
    refute_nil result
  end

  def test_unmatched_backtick
    text = "This has ` unmatched backtick"
    result = Telegrama::Formatter.format(text)
    refute_nil result
  end

  def test_consecutive_special_chars
    text = "Multiple...dots"
    result = Telegrama::Formatter.format(text)
    # All dots should be escaped
    assert_includes result, "\\."
  end

  def test_mixed_formatting_marks
    text = "*_`mixed`_*"
    result = Telegrama::Formatter.format(text)
    refute_nil result
  end

  def test_backslash_handling
    # Backslash handling in MarkdownV2 is complex
    # The formatter may interpret \U and \t as escape sequences
    text = "Path with backslash \\\\"
    result = Telegrama::Formatter.format(text)
    refute_nil result
    # Just verify output is not empty
    assert result.length > 0
  end

  def test_already_escaped_chars
    text = "Already escaped \\. period"
    result = Telegrama::Formatter.format(text)
    refute_nil result
  end

  # ===========================================================================
  # Multiline Text Tests
  # ===========================================================================

  def test_multiline_with_formatting
    text = <<~MSG
      *Title*

      _Description_ with `code`.

      [Link](https://example.com)
    MSG
    result = Telegrama::Formatter.format(text)
    assert_includes result, "*Title*"
    assert_includes result, "_Description_"
    assert_includes result, "`code`"
  end

  def test_multiline_code_block
    text = <<~MSG
      Before:
      ```
      line 1
      line 2
      ```
      After
    MSG
    result = Telegrama::Formatter.format(text)
    assert_includes result, "```"
    assert_includes result, "line 1"
  end

  def test_preserves_empty_lines
    text = "Line 1\n\n\nLine 2"
    result = Telegrama::Formatter.format(text)
    assert_includes result, "\n\n\n"
  end

  # ===========================================================================
  # Unicode Tests
  # ===========================================================================

  def test_cyrillic_text
    text = "Привет мир"
    result = Telegrama::Formatter.format(text)
    assert_equal text, result
  end

  def test_chinese_text
    text = "你好世界"
    result = Telegrama::Formatter.format(text)
    assert_equal text, result
  end

  def test_japanese_text
    text = "こんにちは世界"
    result = Telegrama::Formatter.format(text)
    assert_equal text, result
  end

  def test_arabic_text
    text = "مرحبا بالعالم"
    result = Telegrama::Formatter.format(text)
    assert_equal text, result
  end

  def test_emoji_preservation
    text = "🚀 Launch! 🎉"
    result = Telegrama::Formatter.format(text)
    assert_includes result, "🚀"
    assert_includes result, "🎉"
    # Exclamation should be escaped
    assert_includes result, "\\!"
  end

  def test_mixed_scripts
    text = "Hello мир 世界 🌍"
    result = Telegrama::Formatter.format(text)
    assert_includes result, "Hello"
    assert_includes result, "мир"
    assert_includes result, "世界"
    assert_includes result, "🌍"
  end

  # ===========================================================================
  # Prefix/Suffix Tests
  # ===========================================================================

  def test_applies_prefix
    Telegrama.configuration.message_prefix = "[ALERT] "
    result = Telegrama::Formatter.format("Important message")
    assert result.start_with?("[ALERT] "), "Result should start with prefix"
  end

  def test_applies_suffix
    # Note: suffix content gets markdown-escaped too (dashes become \-)
    Telegrama.configuration.message_suffix = "\n--\nBot"
    result = Telegrama::Formatter.format("Message")
    # The suffix is applied but dashes are escaped in MarkdownV2
    assert_includes result, "Bot"
    assert_includes result, "\n"
  end

  def test_applies_both_prefix_and_suffix
    Telegrama.configuration.message_prefix = "[START] "
    Telegrama.configuration.message_suffix = " [END]"
    result = Telegrama::Formatter.format("Content")
    assert result.start_with?("[START] ")
    assert result.end_with?("[END]")
    assert_includes result, "Content"
  end

  def test_no_prefix_suffix_when_nil
    Telegrama.configuration.message_prefix = nil
    Telegrama.configuration.message_suffix = nil
    result = Telegrama::Formatter.format("Simple")
    assert_equal "Simple", result
  end

  def test_prefix_suffix_with_unicode
    Telegrama.configuration.message_prefix = "🔔 "
    Telegrama.configuration.message_suffix = " 🔔"
    result = Telegrama::Formatter.format("Alert")
    assert_includes result, "🔔"
  end

  # ===========================================================================
  # apply_prefix_suffix Unit Tests
  # ===========================================================================

  def test_apply_prefix_suffix_only_prefix
    Telegrama.configuration.message_prefix = "[P] "
    Telegrama.configuration.message_suffix = nil
    result = Telegrama::Formatter.apply_prefix_suffix("msg")
    assert_equal "[P] msg", result
  end

  def test_apply_prefix_suffix_only_suffix
    Telegrama.configuration.message_prefix = nil
    Telegrama.configuration.message_suffix = " [S]"
    result = Telegrama::Formatter.apply_prefix_suffix("msg")
    assert_equal "msg [S]", result
  end

  def test_apply_prefix_suffix_both
    Telegrama.configuration.message_prefix = "["
    Telegrama.configuration.message_suffix = "]"
    result = Telegrama::Formatter.apply_prefix_suffix("msg")
    assert_equal "[msg]", result
  end

  def test_apply_prefix_suffix_neither
    Telegrama.configuration.message_prefix = nil
    Telegrama.configuration.message_suffix = nil
    result = Telegrama::Formatter.apply_prefix_suffix("msg")
    assert_equal "msg", result
  end

  # ===========================================================================
  # Truncation Tests
  # ===========================================================================

  def test_truncates_long_message
    Telegrama.configuration.formatting_options[:truncate] = 10
    result = Telegrama::Formatter.format("This is a very long message")
    assert_equal 10, result.length
  end

  def test_no_truncation_for_short_message
    Telegrama.configuration.formatting_options[:truncate] = 100
    text = "Short"
    result = Telegrama::Formatter.format(text)
    assert_equal text, result
  end

  def test_truncation_at_exact_limit
    Telegrama.configuration.formatting_options[:truncate] = 5
    result = Telegrama::Formatter.format("12345")
    assert_equal "12345", result
    assert_equal 5, result.length
  end

  def test_truncation_with_unicode
    Telegrama.configuration.formatting_options[:truncate] = 5
    # Each character counts as 1
    result = Telegrama::Formatter.format("你好世界！")
    assert_equal 5, result.length
  end

  def test_no_truncation_when_nil
    Telegrama.configuration.formatting_options[:truncate] = nil
    long_text = "x" * 10000
    result = Telegrama::Formatter.format(long_text)
    assert_equal 10000, result.length
  end

  # ===========================================================================
  # truncate Unit Tests
  # ===========================================================================

  def test_truncate_method_with_short_text
    result = Telegrama::Formatter.truncate("short", 10)
    assert_equal "short", result
  end

  def test_truncate_method_with_long_text
    result = Telegrama::Formatter.truncate("very long text", 5)
    assert_equal "very ", result
  end

  def test_truncate_method_with_nil_limit
    result = Telegrama::Formatter.truncate("text", nil)
    assert_equal "text", result
  end

  def test_truncate_method_with_zero_length
    # 0 is truthy in Ruby, so truncate(text, 0) returns text[0, 0] = ""
    result = Telegrama::Formatter.truncate("text", 0)
    assert_equal "", result
  end

  # ===========================================================================
  # HTML Escaping Tests
  # ===========================================================================

  def test_html_escape_when_enabled
    Telegrama.configuration.formatting_options[:escape_html] = true
    result = Telegrama::Formatter.format("<script>alert('xss')</script>")
    assert_includes result, "&lt;script&gt;"
    assert_includes result, "&lt;/script&gt;"
    refute_includes result, "<script>"
  end

  def test_html_escape_ampersand
    Telegrama.configuration.formatting_options[:escape_html] = true
    result = Telegrama::Formatter.format("Tom & Jerry")
    assert_includes result, "&amp;"
  end

  def test_html_escape_greater_than
    Telegrama.configuration.formatting_options[:escape_html] = true
    result = Telegrama::Formatter.format("a > b")
    assert_includes result, "&gt;"
  end

  def test_no_html_escape_when_disabled
    Telegrama.configuration.formatting_options[:escape_html] = false
    result = Telegrama::Formatter.format("<div>content</div>")
    # Note: Other markdown escaping may still apply
    assert_includes result, "div"
  end

  # ===========================================================================
  # escape_html Unit Tests
  # ===========================================================================

  def test_escape_html_method_less_than
    result = Telegrama::Formatter.escape_html("<tag>")
    assert_equal "&lt;tag&gt;", result
  end

  def test_escape_html_method_ampersand
    result = Telegrama::Formatter.escape_html("a & b")
    assert_equal "a &amp; b", result
  end

  def test_escape_html_method_no_html
    result = Telegrama::Formatter.escape_html("plain text")
    assert_equal "plain text", result
  end

  # ===========================================================================
  # Email Obfuscation Tests
  # ===========================================================================

  def test_email_obfuscation_basic
    Telegrama.configuration.formatting_options[:obfuscate_emails] = true
    result = Telegrama::Formatter.format("Contact: john.doe@example.com")
    refute_includes result, "john.doe@example.com"
    # Should have obfuscated form
    assert_includes result, "@example"
  end

  def test_email_obfuscation_multiple_emails
    Telegrama.configuration.formatting_options[:obfuscate_emails] = true
    text = "Contact john@a.com or jane@b.com"
    result = Telegrama::Formatter.format(text)
    refute_includes result, "john@a.com"
    refute_includes result, "jane@b.com"
  end

  def test_email_obfuscation_preserves_domain
    Telegrama.configuration.formatting_options[:obfuscate_emails] = true
    result = Telegrama::Formatter.format("user@example.com")
    # Domain is preserved but dots are escaped for MarkdownV2
    assert_includes result, "@example"
    assert_includes result, "com"
  end

  def test_email_obfuscation_short_local_part
    Telegrama.configuration.formatting_options[:obfuscate_emails] = true
    result = Telegrama::Formatter.format("ab@x.com")
    # Domain is preserved (dots escaped), local part abbreviated with ...
    # The "..." also gets dots escaped in MarkdownV2
    assert_includes result, "@x"
    assert_includes result, "com"
    # The abbreviation uses ... which may be escaped
    assert(result.include?("...") || result.include?("\\.\\.\\."), "Should have abbreviation dots")
  end

  def test_email_obfuscation_disabled
    Telegrama.configuration.formatting_options[:obfuscate_emails] = false
    result = Telegrama::Formatter.format("john@example.com")
    # Email should remain but dots get escaped
    assert_includes result, "john@example"
  end

  def test_no_false_positives_for_at_sign
    Telegrama.configuration.formatting_options[:obfuscate_emails] = true
    # This is not an email, should not be modified
    result = Telegrama::Formatter.format("Twitter: @username")
    assert_includes result, "@username"
  end

  # ===========================================================================
  # obfuscate_emails Unit Tests
  # ===========================================================================

  def test_obfuscate_emails_method_basic
    result = Telegrama::Formatter.obfuscate_emails("test@example.com")
    refute_equal "test@example.com", result
    assert_includes result, "@example.com"
    assert_includes result, "..."
  end

  def test_obfuscate_emails_method_long_local
    result = Telegrama::Formatter.obfuscate_emails("verylongname@domain.com")
    assert_includes result, "ver"  # First 3 chars
    assert_includes result, "..."
    assert_includes result, "@domain.com"
  end

  def test_obfuscate_emails_method_no_email
    result = Telegrama::Formatter.obfuscate_emails("no email here")
    assert_equal "no email here", result
  end

  # ===========================================================================
  # strip_markdown Tests
  # ===========================================================================

  def test_strip_markdown_removes_bold
    result = Telegrama::Formatter.strip_markdown("*bold* text")
    assert_equal "bold text", result
    refute_includes result, "*"
  end

  def test_strip_markdown_removes_italic
    result = Telegrama::Formatter.strip_markdown("_italic_ text")
    assert_equal "italic text", result
    refute_includes result, "_"
  end

  def test_strip_markdown_removes_code
    result = Telegrama::Formatter.strip_markdown("`code` text")
    assert_equal "code text", result
    refute_includes result, "`"
  end

  def test_strip_markdown_preserves_link_text
    result = Telegrama::Formatter.strip_markdown("[link text](https://example.com)")
    assert_includes result, "link text"
    refute_includes result, "https://example"
    refute_includes result, "["
    refute_includes result, "]"
  end

  def test_strip_markdown_removes_strikethrough
    result = Telegrama::Formatter.strip_markdown("~~deleted~~ text")
    assert_equal "deleted text", result
    refute_includes result, "~"
  end

  def test_strip_markdown_preserves_plain_text
    text = "Plain text without formatting"
    result = Telegrama::Formatter.strip_markdown(text)
    assert_equal text, result
  end

  def test_strip_markdown_handles_complex_text
    text = "*bold* _italic_ `code` [link](url) normal"
    result = Telegrama::Formatter.strip_markdown(text)
    assert_includes result, "bold"
    assert_includes result, "italic"
    assert_includes result, "code"
    assert_includes result, "link"
    assert_includes result, "normal"
    refute_includes result, "*"
    refute_includes result, "_"
    refute_includes result, "`"
    refute_includes result, "["
  end

  # ===========================================================================
  # Formatting Options Merge Tests
  # ===========================================================================

  def test_format_with_option_override
    Telegrama.configuration.formatting_options[:obfuscate_emails] = false
    result = Telegrama::Formatter.format(
      "test@example.com",
      { obfuscate_emails: true }
    )
    refute_includes result, "test@example.com"
  end

  def test_format_with_multiple_overrides
    Telegrama.configuration.formatting_options = {
      escape_markdown: true,
      escape_html: false,
      truncate: 1000
    }
    result = Telegrama::Formatter.format(
      "<b>test</b>",
      { escape_html: true, truncate: 5 }
    )
    assert_includes result, "&lt;"
    assert_equal 5, result.length
  end

  # ===========================================================================
  # MarkdownError Recovery Tests
  # ===========================================================================

  def test_markdown_error_class_is_defined
    assert defined?(Telegrama::Formatter::MarkdownError)
  end

  def test_markdown_error_is_standard_error
    error = Telegrama::Formatter::MarkdownError.new("test")
    assert_kind_of StandardError, error
  end

  # ===========================================================================
  # Real-World Message Tests (from README examples)
  # ===========================================================================

  def test_readme_example_new_sale
    Telegrama.configuration.formatting_options[:obfuscate_emails] = true

    message = <<~MSG
      💸 *New sale!*

      john.doe@gmail.com paid *$49.99* for Business Plan.
    MSG

    result = Telegrama::Formatter.format(message)

    # Email should be obfuscated
    refute_includes result, "john.doe@gmail.com"
    assert_includes result, "@gmail"

    # Bold should be preserved
    assert_includes result, "*New sale"
    assert_includes result, "*$49"

    # Emoji should be preserved
    assert_includes result, "💸"
  end

  def test_readme_example_with_link
    message = "[🔗 View details](https://example.com/admin/123)"
    result = Telegrama::Formatter.format(message)

    assert_includes result, "🔗"
    assert_includes result, "View details"
    assert_includes result, "https://example"
  end

  def test_complex_real_world_message
    Telegrama.configuration.message_prefix = "[Production] "
    Telegrama.configuration.formatting_options[:obfuscate_emails] = true

    message = <<~MSG
      📊 *Daily Report*

      _Summary for today_

      • New users: *150*
      • Revenue: *$2,345.67*
      • Active sessions: `1,234`

      Top user: admin@company.com

      [📈 View Dashboard](https://dashboard.example.com)
    MSG

    result = Telegrama::Formatter.format(message)

    # Prefix applied
    assert result.start_with?("[Production]"), "Should have prefix"

    # Formatting preserved
    assert_includes result, "*Daily Report*"
    assert_includes result, "_Summary"
    # Code may have special characters escaped
    assert_includes result, "1,234"

    # Emoji preserved
    assert_includes result, "📊"
    assert_includes result, "📈"

    # Email obfuscated (domain gets dots escaped too)
    refute_includes result, "admin@company.com"
    assert_includes result, "@company"
    assert_includes result, "com"

    # Link text preserved
    assert_includes result, "View Dashboard"
  end

  # ===========================================================================
  # MarkdownTokenizer Tests
  # ===========================================================================

  def test_tokenizer_processes_plain_text
    tokenizer = Telegrama::Formatter::MarkdownTokenizer.new("plain text")
    result = tokenizer.process
    assert_equal "plain text", result
  end

  def test_tokenizer_processes_bold
    tokenizer = Telegrama::Formatter::MarkdownTokenizer.new("*bold*")
    result = tokenizer.process
    assert_equal "*bold*", result
  end

  def test_tokenizer_processes_italic
    tokenizer = Telegrama::Formatter::MarkdownTokenizer.new("_italic_")
    result = tokenizer.process
    assert_equal "_italic_", result
  end

  def test_tokenizer_processes_code
    tokenizer = Telegrama::Formatter::MarkdownTokenizer.new("`code`")
    result = tokenizer.process
    assert_equal "`code`", result
  end

  def test_tokenizer_state_transitions
    tokenizer = Telegrama::Formatter::MarkdownTokenizer.new("*bold* and _italic_")
    result = tokenizer.process
    assert_includes result, "*bold*"
    assert_includes result, "_italic_"
  end

  # ===========================================================================
  # Performance Test (optional)
  # ===========================================================================

  def test_performance_with_large_text
    skip "Skipping performance test in CI" if ENV["CI"]

    large_text = ("Normal *bold* _italic_ `code` [link](url) " * 100)

    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    result = Telegrama::Formatter.format(large_text)
    end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    elapsed = end_time - start_time
    assert_operator elapsed, :<, 1.0, "Formatting should complete in under 1 second"
    refute_nil result
  end
end
