# frozen_string_literal: true

require "test_helper"

class Telegrama::SendMessageJobTest < TelegramaTestCase
  def setup
    super
    configure_telegrama(
      bot_token: "test-token",
      chat_id: 123456
    )
  end

  # ===========================================================================
  # Basic Job Tests
  # ===========================================================================

  def test_job_class_exists
    assert defined?(Telegrama::SendMessageJob)
  end

  def test_job_inherits_from_active_job
    assert_operator Telegrama::SendMessageJob, :<, ActiveJob::Base
  end

  def test_job_can_be_instantiated
    job = Telegrama::SendMessageJob.new
    assert_kind_of Telegrama::SendMessageJob, job
  end

  # ===========================================================================
  # Job Execution Tests
  # ===========================================================================

  def test_perform_sends_message
    stub_telegram_success

    job = Telegrama::SendMessageJob.new
    response = job.perform("Hello from job!")

    assert_kind_of OpenStruct, response
    assert_equal 200, response.code
    assert_telegram_request_made
  end

  def test_perform_with_options
    stub_telegram_success

    job = Telegrama::SendMessageJob.new
    response = job.perform("Test", { chat_id: 999, parse_mode: "HTML" })

    assert_equal 200, response.code
    assert_telegram_request_with_body do |body|
      body[:chat_id] == 999 && body[:parse_mode] == "HTML"
    end
  end

  def test_perform_raises_on_api_error
    stub_telegram_failure(error_code: 400, description: "Bad Request")

    job = Telegrama::SendMessageJob.new
    assert_raises(Telegrama::Error) { job.perform("Test") }
  end

  # ===========================================================================
  # Job Enqueueing Tests
  # ===========================================================================

  def test_perform_later_enqueues_job
    before_count = ActiveJob::Base.queue_adapter.enqueued_jobs.size

    Telegrama::SendMessageJob.perform_later("Async message")

    after_count = ActiveJob::Base.queue_adapter.enqueued_jobs.size
    assert_equal before_count + 1, after_count
  end

  def test_enqueued_job_has_correct_class
    Telegrama::SendMessageJob.perform_later("Test")

    enqueued = ActiveJob::Base.queue_adapter.enqueued_jobs.last
    assert_equal "Telegrama::SendMessageJob", enqueued[:job].name
  end

  def test_enqueued_job_has_correct_arguments
    Telegrama::SendMessageJob.perform_later("Test message", { chat_id: 999 })

    enqueued = ActiveJob::Base.queue_adapter.enqueued_jobs.last
    args = enqueued[:args]
    assert_equal "Test message", args[0]
    assert_equal 999, args[1]["chat_id"]
  end

  def test_enqueued_job_uses_default_queue
    Telegrama::SendMessageJob.perform_later("Test")

    enqueued = ActiveJob::Base.queue_adapter.enqueued_jobs.last
    assert_equal "default", enqueued[:queue]
  end

  def test_enqueued_job_uses_custom_queue
    Telegrama::SendMessageJob.set(queue: "critical").perform_later("Urgent!")

    enqueued = ActiveJob::Base.queue_adapter.enqueued_jobs.last
    assert_equal "critical", enqueued[:queue]
  end

  # ===========================================================================
  # Integration with Telegrama.send_message
  # ===========================================================================

  def test_telegrama_send_message_enqueues_job_when_async
    configure_telegrama(
      bot_token: "test-token",
      chat_id: 123,
      async: true,
      queue: "notifications"
    )

    before_count = ActiveJob::Base.queue_adapter.enqueued_jobs.size

    Telegrama.send_message("Async message")

    after_count = ActiveJob::Base.queue_adapter.enqueued_jobs.size
    assert_equal before_count + 1, after_count

    enqueued = ActiveJob::Base.queue_adapter.enqueued_jobs.last
    assert_equal "notifications", enqueued[:queue]
    assert_equal "Telegrama::SendMessageJob", enqueued[:job].name
  end

  def test_telegrama_send_message_sync_does_not_enqueue
    stub_telegram_success

    configure_telegrama(
      bot_token: "test-token",
      chat_id: 123,
      async: false
    )

    before_count = ActiveJob::Base.queue_adapter.enqueued_jobs.size

    Telegrama.send_message("Sync message")

    after_count = ActiveJob::Base.queue_adapter.enqueued_jobs.size
    assert_equal before_count, after_count
  end

  # ===========================================================================
  # Edge Cases
  # ===========================================================================

  def test_perform_with_empty_message
    stub_telegram_success

    job = Telegrama::SendMessageJob.new
    response = job.perform("")

    assert_equal 200, response.code
  end

  def test_perform_with_unicode_message
    stub_telegram_success

    job = Telegrama::SendMessageJob.new
    response = job.perform("Привет 🌍")

    assert_equal 200, response.code
  end

  def test_perform_with_long_message
    stub_telegram_success

    job = Telegrama::SendMessageJob.new
    response = job.perform("x" * 5000)

    assert_equal 200, response.code
  end

  def test_perform_with_empty_options
    stub_telegram_success

    job = Telegrama::SendMessageJob.new
    response = job.perform("Test", {})

    assert_equal 200, response.code
  end

  def test_perform_with_nil_options
    stub_telegram_success

    job = Telegrama::SendMessageJob.new
    # When options is omitted, it defaults to {}
    response = job.perform("Test")

    assert_equal 200, response.code
  end

  # ===========================================================================
  # Multiple Enqueue Tests
  # ===========================================================================

  def test_multiple_jobs_can_be_enqueued
    3.times { |i| Telegrama::SendMessageJob.perform_later("Message #{i}") }

    jobs = ActiveJob::Base.queue_adapter.enqueued_jobs.last(3)
    assert_equal 3, jobs.size
    jobs.each do |job|
      assert_equal "Telegrama::SendMessageJob", job[:job].name
    end
  end

  def test_jobs_preserve_order
    Telegrama::SendMessageJob.perform_later("First")
    Telegrama::SendMessageJob.perform_later("Second")
    Telegrama::SendMessageJob.perform_later("Third")

    jobs = ActiveJob::Base.queue_adapter.enqueued_jobs.last(3)
    assert_equal "First", jobs[0][:args][0]
    assert_equal "Second", jobs[1][:args][0]
    assert_equal "Third", jobs[2][:args][0]
  end

  # ===========================================================================
  # Serialization Tests
  # ===========================================================================

  def test_job_arguments_are_serializable
    # Complex options should serialize properly
    options = {
      chat_id: 12345,
      parse_mode: "HTML",
      formatting: { obfuscate_emails: true }
    }

    Telegrama::SendMessageJob.perform_later("Test", options)

    enqueued = ActiveJob::Base.queue_adapter.enqueued_jobs.last
    args = enqueued[:args]

    assert_equal "Test", args[0]
    assert_equal 12345, args[1]["chat_id"]
    assert_equal "HTML", args[1]["parse_mode"]
  end
end
