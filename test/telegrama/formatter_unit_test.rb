require "test_helper"

class Telegrama::FormatterUnitTest < Minitest::Test
  def setup
    Telegrama.instance_variable_set(:@configuration, Telegrama::Configuration.new)
    Telegrama.configuration.bot_token = 'x'
    Telegrama.configuration.message_prefix = nil
    Telegrama.configuration.message_suffix = nil
    Telegrama.configuration.formatting_options = { escape_markdown: true, obfuscate_emails: false, escape_html: false, truncate: 4096 }
  end

  def test_apply_prefix_suffix_only_prefix
    Telegrama.configuration.message_prefix = "[P] "
    result = Telegrama::Formatter.apply_prefix_suffix("msg")
    assert_equal "[P] msg", result
  end

  def test_apply_prefix_suffix_only_suffix
    Telegrama.configuration.message_suffix = "\n--\nSent via Telegrama"
    result = Telegrama::Formatter.apply_prefix_suffix("msg")
    assert_equal "msg\n--\nSent via Telegrama", result
  end

  def test_strip_markdown
    text = "*b*_i_`c` [l](https://e)"
    # strip_markdown is a simple regex; ensure markdown elements are removed
    result = Telegrama::Formatter.strip_markdown(text)
    refute_includes result, '*'
    refute_includes result, '_'
    refute_includes result, '`'
    refute_includes result, '['
    assert_includes result, 'b'
    assert_includes result, 'i'
    assert_includes result, 'c'
  end

  def test_html_to_telegram_markdown
    html = '<p><strong>b</strong> and <em>i</em> and <code>x</code> <a href="https://example.com">l</a></p>'
    Telegrama.configuration.formatting_options[:escape_markdown] = true
    result = Telegrama::Formatter.html_to_telegram_markdown(html)
    assert_includes result, "*b*"
    assert_includes result, "_i_"
    assert_includes result, "`x`"
    # URL escaping is allowed; just check parts
    assert_includes result, "[l](https://example"
    assert_includes result, "example"
  end

  def test_truncate
    assert_equal "abc", Telegrama::Formatter.truncate("abcdef", 3)
    assert_equal "abcdef", Telegrama::Formatter.truncate("abcdef", 10)
  end
end