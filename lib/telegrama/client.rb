module Telegrama
  class Client
    def send_message(message, options = {})
      # Allow chat ID override; fallback to config default
      chat_id = options.delete(:chat_id) || Telegrama.configuration.chat_id

      # Allow runtime formatting options, merging with configured defaults
      formatting_opts = options.delete(:formatting) || {}
      formatted_message = Formatter.format(message, formatting_opts)

      payload = {
        chat_id: chat_id,
        text: formatted_message,
        parse_mode: options[:parse_mode] || Telegrama.configuration.default_parse_mode,
        disable_web_page_preview: options.fetch(:disable_web_page_preview, true)
      }

      perform_request(payload)
    end

    private

    def perform_request(payload)
      uri = URI("https://api.telegram.org/bot#{Telegrama.configuration.bot_token}/sendMessage")
      request = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
      request.body = payload.to_json

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      unless response.is_a?(Net::HTTPSuccess)
        error_info = JSON.parse(response.body) rescue {}
        error_description = error_info["description"] || response.body
        logger.error("Telegrama API error for chat_id #{payload[:chat_id]}: #{error_description}")
        raise Error, "Telegram API error for chat_id #{payload[:chat_id]}: #{error_description}"
      end

      response
    rescue StandardError => e
      logger.error("Failed to send Telegram message: #{e.message}")
      raise Error, "Failed to send Telegram message: #{e.message}"
    end

    def logger
      defined?(Rails) && Rails.respond_to?(:logger) ? Rails.logger : Logger.new($stdout)
    end
  end
end
