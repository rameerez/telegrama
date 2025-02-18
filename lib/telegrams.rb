# frozen_string_literal: true

# Require standard libraries that our gem depends on
require "net/http"
require "uri"
require "json"
require "cgi"

# Require our gem files
require_relative "telegrams/error"
require_relative "telegrams/version"
require_relative "telegrams/configuration"
require_relative "telegrams/formatter"
require_relative "telegrams/client"
require_relative "telegrams/send_message_job"

module Telegrams
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
    # This way, if nothing’s been set up, we get a descriptive error instead of a low-level one.
    def send_message(message, options = {})
      configuration.validate!
      if configuration.deliver_message_async
        SendMessageJob.set(queue: configuration.deliver_message_queue).perform_later(message, options)
      else
        Client.new.send_message(message, options)
      end
    end

  end
end
