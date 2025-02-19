module Telegrama
  module Formatter
    MARKDOWN_SPECIAL_CHARS = %w[_ * [ ] ( ) ~ ` > # + - = | { } . !].freeze
    # Characters that should always be escaped in Telegram messages, even when Markdown is enabled
    ALWAYS_ESCAPE_CHARS = %w[. ! -].freeze
    # Characters used for Markdown formatting that need special handling
    MARKDOWN_FORMAT_CHARS = %w[* _].freeze

    def self.format(text, options = {})
      # Merge defaults with any runtime overrides
      defaults = Telegrama.configuration.formatting_options || {}
      opts = defaults.merge(options)

      text = text.to_s

      # Apply prefix and suffix if configured
      prefix = Telegrama.configuration.message_prefix
      suffix = Telegrama.configuration.message_suffix

      text = "#{prefix}#{text}" if prefix
      text = "#{text}#{suffix}" if suffix

      text = obfuscate_emails(text) if opts[:obfuscate_emails]
      text = escape_html(text)    if opts[:escape_html]
      if opts[:escape_markdown]
        text = escape_markdown(text)
      else
        # When Markdown is enabled (escape_markdown: false), we still need to escape some special characters
        text = escape_special_chars(text)
      end
      text = truncate(text, opts[:truncate]) if opts[:truncate]

      text
    end

    def self.escape_markdown(text)
      MARKDOWN_SPECIAL_CHARS.each do |char|
        text = text.gsub(/(?<!\\)#{Regexp.escape(char)}/, "\\#{char}")
      end
      text
    end

    def self.escape_special_chars(text)
      # First escape non-formatting special characters
      ALWAYS_ESCAPE_CHARS.each do |char|
        text = text.gsub(/(?<!\\)#{Regexp.escape(char)}/, "\\#{char}")
      end

      # Then handle formatting characters (* and _) by only escaping them when they're not paired
      MARKDOWN_FORMAT_CHARS.each do |char|
        # Count unescaped occurrences
        count = text.scan(/(?<!\\)#{Regexp.escape(char)}/).count

        if count.odd?
          # If we have an odd count, escape all occurrences that aren't already escaped
          text = text.gsub(/(?<!\\)#{Regexp.escape(char)}/, "\\#{char}")
        end
      end

      text
    end

    def self.obfuscate_emails(text)
      text.gsub(/\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b/) do |email|
        local, domain = email.split('@')
        obfuscated_local = local.length > 4 ? "#{local[0..2]}...#{local[-1]}" : "#{local[0]}..."
        "#{obfuscated_local}@#{domain}"
      end
    end

    def self.escape_html(text)
      text.gsub(/[<>&]/, '<' => '&lt;', '>' => '&gt;', '&' => '&amp;')
    end

    def self.truncate(text, max_length)
      text.length > max_length ? text[0, max_length] : text
    end
  end
end
