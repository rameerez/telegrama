require 'ostruct'
require 'logger'
require 'net/http'
require 'json'

module Telegrama
  class Client
    def initialize(config = {})
      @config = config
      @fallback_attempts = 0
      @max_fallback_attempts = 2
    end

    # Send a message with built-in error handling and fallbacks
    def send_message(message, options = {})
      # Allow chat ID override; fallback to config default
      chat_id = options.delete(:chat_id) || Telegrama.configuration.chat_id

      # Get client options from config
      client_opts = Telegrama.configuration.client_options || {}
      client_opts = client_opts.merge(@config)

      # Default to MarkdownV2 parse mode unless explicitly overridden
      parse_mode = options[:parse_mode] || Telegrama.configuration.default_parse_mode

      # Allow runtime formatting options, merging with configured defaults
      formatting_opts = options.delete(:formatting) || {}

      # Add parse mode specific options
      if parse_mode == 'MarkdownV2'
        formatting_opts[:escape_markdown] = true unless formatting_opts.key?(:escape_markdown)
      elsif parse_mode == 'HTML'
        formatting_opts[:escape_html] = true unless formatting_opts.key?(:escape_html)
      end

      # Format the message text with our formatter
      formatted_message = Formatter.format(message, formatting_opts)

      # Reset fallback attempts counter
      @fallback_attempts = 0

      # Use a loop to implement fallback strategy
      begin
        # Prepare the request payload
        payload = {
          chat_id: chat_id,
          text: formatted_message,
          parse_mode: parse_mode,
          disable_web_page_preview: options.fetch(:disable_web_page_preview,
                                                 Telegrama.configuration.disable_web_page_preview)
        }

        # Additional options such as reply_markup can be added here
        payload.merge!(options.select { |k, _| [:reply_markup, :reply_to_message_id].include?(k) })

        # Make the API request
        response = perform_request(payload, client_opts)

        # If successful, reset fallback counter and return the response
        @fallback_attempts = 0
        return response

      rescue Error => e
        # Log the error for debugging
        begin
          Telegrama.log_error("Error sending message: #{e.message}")
        rescue => _log_error
          # Ignore logging errors in tests
        end

        # Track this attempt
        @fallback_attempts += 1

        # Try fallback strategies if we haven't exceeded the limit
        if @fallback_attempts < 3
          # If we were using MarkdownV2, try HTML as fallback
          if parse_mode == 'MarkdownV2' && @fallback_attempts == 1
            begin
              Telegrama.log_info("Falling back to HTML format")
            rescue => _log_error
              # Ignore logging errors
            end

            # Switch to HTML formatting
            parse_mode = 'HTML'
            formatting_opts = { escape_html: true, escape_markdown: false }
            formatted_message = Formatter.format(message, formatting_opts)

            # Retry the request
            retry

          # If HTML fails too, try plain text
          elsif parse_mode == 'HTML' && @fallback_attempts == 2
            begin
              Telegrama.log_info("Falling back to plain text format")
            rescue => _log_error
              # Ignore logging errors
            end

            # Switch to plain text (no special formatting)
            parse_mode = nil
            formatting_opts = { escape_markdown: false, escape_html: false }
            formatted_message = Formatter.format(message, formatting_opts)

            # Retry the request
            retry
          end
        end

        # If we've exhausted fallbacks or this is a different error, re-raise
        raise
      end
    end

    private

    def perform_request(payload, options = {})
      uri = URI("https://api.telegram.org/bot#{Telegrama.configuration.bot_token}/sendMessage")
      request = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
      request.body = payload.to_json

      # Extract timeout from options
      timeout = options[:timeout] || 30

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true,
                                read_timeout: timeout, open_timeout: timeout) do |http|
        http.request(request)
      end

      # Parse the response body
      begin
        response_body = JSON.parse(response.body, symbolize_names: true)
      rescue JSON::ParserError
        response_body = { ok: false, description: "Invalid JSON response" }
      end

      # Create a response object with both status code and parsed body
      response_obj = OpenStruct.new(
        code: response.code.to_i,
        body: response_body
      )

      unless response.is_a?(Net::HTTPSuccess) && response_body[:ok]
        error_description = response_body[:description] || response.body
        logger.error("Telegrama API error for chat_id #{payload[:chat_id]}: #{error_description}")
        raise Error, "Telegram API error for chat_id #{payload[:chat_id]}: #{error_description}"
      end

      response_obj
    rescue StandardError => e
      # Don't log API errors again, they're already logged above
      unless e.is_a?(Error)
        logger.error("Failed to send Telegram message: #{e.message}")
      end
      raise Error, "Failed to send Telegram message: #{e.message}"
    end

    def logger
      defined?(Rails) && Rails.respond_to?(:logger) ? Rails.logger : Logger.new($stdout)
    end
  end

  class Error < StandardError; end
end
