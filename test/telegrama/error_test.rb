# frozen_string_literal: true

require "test_helper"

class Telegrama::ErrorTest < TelegramaTestCase
  # ===========================================================================
  # Basic Error Class Tests
  # ===========================================================================

  def test_error_class_exists
    assert defined?(Telegrama::Error)
  end

  def test_error_inherits_from_standard_error
    assert_operator Telegrama::Error, :<, StandardError
  end

  def test_error_can_be_instantiated_with_message
    error = Telegrama::Error.new("Something went wrong")
    assert_equal "Something went wrong", error.message
  end

  def test_error_can_be_instantiated_without_message
    error = Telegrama::Error.new
    assert_kind_of Telegrama::Error, error
  end

  def test_error_can_be_raised_and_rescued
    raised = false
    begin
      raise Telegrama::Error, "Test error"
    rescue Telegrama::Error => e
      raised = true
      assert_equal "Test error", e.message
    end
    assert raised, "Error should have been raised and rescued"
  end

  def test_error_can_be_rescued_as_standard_error
    raised = false
    begin
      raise Telegrama::Error, "Test error"
    rescue StandardError => e
      raised = true
      assert_kind_of Telegrama::Error, e
    end
    assert raised, "Error should have been rescued as StandardError"
  end

  def test_error_has_backtrace
    begin
      raise Telegrama::Error, "Test error"
    rescue Telegrama::Error => e
      refute_nil e.backtrace
      assert_kind_of Array, e.backtrace
    end
  end

  # ===========================================================================
  # Error Propagation Tests
  # ===========================================================================

  def test_error_propagates_through_call_stack
    def inner_method
      raise Telegrama::Error, "Inner error"
    end

    def outer_method
      inner_method
    end

    error = assert_raises(Telegrama::Error) { outer_method }
    assert_equal "Inner error", error.message
    assert_includes error.backtrace.first, "inner_method"
  end

  def test_error_can_wrap_original_error
    original_error = StandardError.new("Original error")
    wrapped_error = Telegrama::Error.new("Wrapped: #{original_error.message}")

    assert_equal "Wrapped: Original error", wrapped_error.message
  end

  # ===========================================================================
  # Formatter Error Tests
  # ===========================================================================

  def test_markdown_error_class_exists
    assert defined?(Telegrama::Formatter::MarkdownError)
  end

  def test_markdown_error_inherits_from_standard_error
    assert_operator Telegrama::Formatter::MarkdownError, :<, StandardError
  end

  def test_markdown_error_can_be_instantiated
    error = Telegrama::Formatter::MarkdownError.new("Markdown parsing failed")
    assert_equal "Markdown parsing failed", error.message
  end

  def test_markdown_error_can_be_raised_and_rescued
    raised = false
    begin
      raise Telegrama::Formatter::MarkdownError, "Invalid markdown"
    rescue Telegrama::Formatter::MarkdownError => e
      raised = true
      assert_equal "Invalid markdown", e.message
    end
    assert raised, "MarkdownError should have been raised and rescued"
  end

  def test_markdown_error_is_not_same_as_main_error
    refute_equal Telegrama::Error, Telegrama::Formatter::MarkdownError
  end

  # ===========================================================================
  # Error Messages Edge Cases
  # ===========================================================================

  def test_error_with_empty_message
    error = Telegrama::Error.new("")
    assert_equal "", error.message
  end

  def test_error_with_unicode_message
    error = Telegrama::Error.new("Ошибка: 失败 🚫")
    assert_equal "Ошибка: 失败 🚫", error.message
  end

  def test_error_with_very_long_message
    long_message = "x" * 10_000
    error = Telegrama::Error.new(long_message)
    assert_equal long_message, error.message
    assert_equal 10_000, error.message.length
  end

  def test_error_with_special_characters
    error = Telegrama::Error.new("Error with special chars: \n\t\r\\\"'")
    assert_includes error.message, "\n"
    assert_includes error.message, "\t"
  end

  def test_error_with_nil_converted_to_message
    # Ruby's StandardError converts nil to empty string
    error = Telegrama::Error.new(nil)
    assert_kind_of String, error.message
  end
end
