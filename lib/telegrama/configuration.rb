# frozen_string_literal: true

module Telegrama
  class Configuration

    # Your Telegram Bot API token
    attr_accessor :bot_token

    # Default chat ID for sending messages.
    # You can override this on the fly when sending messages.
    attr_accessor :chat_id

    # Default parse mode for messages (e.g. "MarkdownV2" or "HTML").
    attr_accessor :default_parse_mode

    # Whether to disable web page previews by default.
    attr_accessor :disable_web_page_preview

    # =========================================
    # Formatting Options
    # =========================================

    # Formatting options used by the Formatter module.
    # Available keys:
    #   :escape_markdown   (Boolean) - Escape Telegram markdown special characters.
    #   :obfuscate_emails  (Boolean) - Obfuscate email addresses found in messages.
    #   :escape_html       (Boolean) - Escape HTML entities (<, >, &).
    #   :truncate          (Integer) - Maximum allowed message length.
    attr_accessor :formatting_options

    # Whether to deliver messages asynchronously via ActiveJob.
    # Defaults to false
    attr_accessor :deliver_message_async

    # The ActiveJob queue name to use when enqueuing messages.
    # Defaults to 'default'
    attr_accessor :deliver_message_queue

    def initialize
      # Credentials (must be set via initializer)
      @bot_token = nil
      @chat_id = nil

      # Defaults for message formatting
      @default_parse_mode = 'MarkdownV2'
      @disable_web_page_preview = true

      # Sensible defaults for formatting options.
      @formatting_options = {
        escape_markdown: true,
        obfuscate_emails: false,
        escape_html: false,
        truncate: 4096
      }

      @deliver_message_async = false
      @deliver_message_queue = 'default'
    end

    # Validate the configuration.
    # Raise descriptive errors if required settings are missing or invalid.
    def validate!
      validate_bot_token!
      validate_default_parse_mode!
      validate_formatting_options!
      true
    end

    private

    def validate_bot_token!
      if bot_token.nil? || bot_token.strip.empty?
        raise ArgumentError, "Telegrama configuration error: bot_token cannot be blank."
      end
    end

    def validate_default_parse_mode!
      allowed_modes = ['MarkdownV2', 'HTML', nil]
      unless allowed_modes.include?(default_parse_mode)
        raise ArgumentError, "Telegrama configuration error: default_parse_mode must be one of #{allowed_modes.inspect}."
      end
    end

    def validate_formatting_options!
      unless formatting_options.is_a?(Hash)
        raise ArgumentError, "Telegrama configuration error: formatting_options must be a hash."
      end

      %i[escape_markdown obfuscate_emails escape_html].each do |key|
        if formatting_options.key?(key) && ![true, false].include?(formatting_options[key])
          raise ArgumentError, "Telegrama configuration error: formatting_options[:#{key}] must be true or false."
        end
      end

      if formatting_options.key?(:truncate)
        truncate_val = formatting_options[:truncate]
        unless truncate_val.is_a?(Integer) && truncate_val.positive?
          raise ArgumentError, "Telegrama configuration error: formatting_options[:truncate] must be a positive integer."
        end
      end
    end
  end
end
