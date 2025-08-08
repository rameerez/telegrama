require "test_helper"

class Telegrama::ApiTest < Minitest::Test
  def setup
    Telegrama::TestState.reset
    Telegrama.instance_variable_set(:@configuration, Telegrama::Configuration.new)
    Telegrama.configuration.bot_token = 'test-token'
    Telegrama.configuration.chat_id = 333
  end

  def test_send_message_sync
    Telegrama.configuration.deliver_message_async = false
    response = Telegrama.send_message("sync message")
    assert_equal 200, response.code
    assert response.body[:ok]
    assert_equal 'sync message', response.body[:result][:text]
  end

  def test_send_message_async_enqueues_job
    Telegrama.configuration.deliver_message_async = true
    Telegrama.configuration.deliver_message_queue = 'critical'

    before = ActiveJob::Base.queue_adapter.enqueued_jobs.dup
    Telegrama.send_message("async message", parse_mode: 'HTML')
    after = ActiveJob::Base.queue_adapter.enqueued_jobs

    assert_equal before.size + 1, after.size
    enqueued = after.last
    assert_equal 'critical', enqueued[:queue]
    assert_equal 'Telegrama::SendMessageJob', enqueued[:job].name
    # ActiveJob serializes symbols to strings with metadata
    args = enqueued[:args]
    assert_equal "async message", args[0]
    assert_equal "HTML", args[1]["parse_mode"]
  end

  def test_send_message_requires_configuration
    Telegrama.instance_variable_set(:@configuration, Telegrama::Configuration.new)
    Telegrama.configuration.bot_token = nil

    error = assert_raises(ArgumentError) { Telegrama.send_message("msg") }
    assert_includes error.message, 'bot_token cannot be blank'
  end
end