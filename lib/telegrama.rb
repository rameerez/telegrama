# frozen_string_literal: true

# Require standard libraries that our gem depends on
require "net/http"
require "uri"
require "json"
require "cgi"

# Require our gem files
require_relative "telegrama/error"
require_relative "telegrama/version"
require_relative "telegrama/configuration"
require_relative "telegrama/formatter"
require_relative "telegrama/client"
require_relative "telegrama/send_message_job"

module Telegrama
  class << self
    # Returns the configuration object.
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
      configuration.validate!
    end

    # Sends a message using the configured settings.
    # Before sending, we validate the configuration.
    # This way, if nothing's been set up, we get a descriptive error instead of a low-level one.
    def send_message(message, options = {})
      configuration.validate!
      if configuration.deliver_message_async
        SendMessageJob.set(queue: configuration.deliver_message_queue).perform_later(message, options)
      else
        Client.new.send_message(message, options)
      end
    end

    # Helper method for logging errors
    def log_error(message)
      if defined?(Rails) && Rails.respond_to?(:logger)
        Rails.logger.error("[Telegrama] #{message}")
      else
        warn("[Telegrama] #{message}")
      end
    end

    # Helper method for logging info messages
    def log_info(message)
      if defined?(Rails) && Rails.respond_to?(:logger)
        Rails.logger.info("[Telegrama] #{message}")
      else
        puts("[Telegrama] #{message}")
      end
    end
  end
end
