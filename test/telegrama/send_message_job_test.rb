require "test_helper"

class Telegrama::SendMessageJobTest < Minitest::Test
  def setup
    Telegrama.instance_variable_set(:@configuration, Telegrama::Configuration.new)
    Telegrama.configuration.bot_token = 'token'
    Telegrama.configuration.chat_id = 444
  end

  def test_perform_invokes_client
    job = Telegrama::SendMessageJob.new
    response = job.perform("hello job", {})
    assert_kind_of OpenStruct, response
    assert_equal 200, response.code

    # Enqueue and verify
    before = ActiveJob::Base.queue_adapter.enqueued_jobs.dup
    Telegrama::SendMessageJob.perform_later("hi", {})
    after = ActiveJob::Base.queue_adapter.enqueued_jobs
    assert_equal before.size + 1, after.size
    enqueued = after.last
    assert_equal 'default', enqueued[:queue]
    assert_equal 'Telegrama::SendMessageJob', enqueued[:job].name
  end
end