module Telegrams
  class SendMessageJob < ActiveJob::Base
    # No default queue provided here -- it's passed from the job call instead

    def perform(message, options = {})
      Client.new.send_message(message, options)
    end
  end
end
