# frozen_string_literal: true

require "test_helper"

# Inline keyboards are the one part of a Telegram message that fails LOUDLY and
# ENTIRELY: an over-long `callback_data`, a blank label or a relative path does
# not degrade to a message without buttons — Telegram rejects the whole
# sendMessage, so the alert nobody could act on is also the alert nobody
# received. Every assertion here is about catching that in Ruby, at the call
# site, with a message that says what to fix.
class Telegrama::InlineKeyboardTest < TelegramaTestCase
  # ===========================================================================
  # The shape Telegram expects
  # ===========================================================================

  def test_a_single_url_button_is_one_row_with_one_button
    keyboard = Telegrama::InlineKeyboard.url("Abrir" => "https://example.com/a")

    assert_equal(
      { inline_keyboard: [ [ { text: "Abrir", url: "https://example.com/a" } ] ] },
      keyboard.to_h
    )
  end

  def test_a_single_callback_button_is_one_row_with_one_button
    keyboard = Telegrama::InlineKeyboard.callback("Lo veo yo" => "claim:42")

    assert_equal(
      { inline_keyboard: [ [ { text: "Lo veo yo", callback_data: "claim:42" } ] ] },
      keyboard.to_h
    )
  end

  def test_rows_stack_in_the_order_they_were_added
    keyboard = Telegrama::InlineKeyboard.new
      .row(url: { "Primera" => "https://example.com/1" })
      .row(url: { "Segunda" => "https://example.com/2" })

    assert_equal %w[Primera Segunda], keyboard.to_h[:inline_keyboard].map { |row| row.first[:text] }
  end

  def test_buttons_in_one_row_keep_their_hash_order
    keyboard = Telegrama::InlineKeyboard.new.row(
      url: { "Cola" => "https://example.com/queue", "Ficha" => "https://example.com/user" }
    )

    assert_equal %w[Cola Ficha], keyboard.to_h[:inline_keyboard].first.map { |button| button[:text] }
  end

  def test_a_row_may_mix_kinds_and_renders_urls_before_callbacks
    # Documented order, so a mixed row is predictable without the caller having
    # to think about it. Anyone needing a different interleaving adds two rows.
    keyboard = Telegrama::InlineKeyboard.new.row(
      callback: { "Silenciar" => "mute:1" },
      url: { "Abrir" => "https://example.com/a" }
    )

    assert_equal(
      [ { text: "Abrir", url: "https://example.com/a" }, { text: "Silenciar", callback_data: "mute:1" } ],
      keyboard.to_h[:inline_keyboard].first
    )
  end

  def test_row_returns_self_so_it_chains
    keyboard = Telegrama::InlineKeyboard.new

    assert_same keyboard, keyboard.row(url: { "Abrir" => "https://example.com" })
  end

  # ===========================================================================
  # Serialization — the client posts JSON, so the object must survive to_json
  # ===========================================================================

  def test_to_json_produces_the_telegram_payload
    keyboard = Telegrama::InlineKeyboard.url("Abrir" => "https://example.com/a")

    assert_equal(
      { "inline_keyboard" => [ [ { "text" => "Abrir", "url" => "https://example.com/a" } ] ] },
      JSON.parse(keyboard.to_json)
    )
  end

  def test_nesting_inside_a_payload_hash_serializes_correctly
    # This is exactly what Client#perform_request does with reply_markup: the
    # keyboard is nested, then the WHOLE payload is dumped in one call. An
    # object without to_json would land as "#<Telegrama::InlineKeyboard…>".
    payload = { chat_id: 1, reply_markup: Telegrama::InlineKeyboard.url("Abrir" => "https://example.com") }

    assert_equal(
      { "text" => "Abrir", "url" => "https://example.com" },
      JSON.parse(payload.to_json).dig("reply_markup", "inline_keyboard", 0, 0)
    )
  end

  def test_as_json_matches_to_h_for_active_support_callers
    keyboard = Telegrama::InlineKeyboard.url("Abrir" => "https://example.com")

    assert_equal keyboard.to_h, keyboard.as_json
  end

  # ===========================================================================
  # callback_data: 1-64 BYTES (Bot API). Bytes, not characters — the emoji trap.
  # ===========================================================================

  def test_callback_data_at_the_64_byte_limit_is_accepted
    keyboard = Telegrama::InlineKeyboard.callback("Ok" => "a" * 64)

    assert_equal 64, keyboard.to_h[:inline_keyboard].first.first[:callback_data].bytesize
  end

  def test_callback_data_over_64_bytes_is_refused_with_the_measurement
    error = assert_raises(ArgumentError) do
      Telegrama::InlineKeyboard.callback("Ok" => "a" * 65)
    end

    assert_includes error.message, "65 bytes"
    assert_includes error.message, "64"
  end

  def test_callback_data_is_measured_in_bytes_not_characters
    # 33 emoji are 33 characters but 132 bytes. Telegram counts bytes, so a
    # length check would have waved this through and lost the whole message.
    emoji = "🚨" * 33

    assert_equal 33, emoji.length
    error = assert_raises(ArgumentError) { Telegrama::InlineKeyboard.callback("Ok" => emoji) }

    assert_includes error.message, "132 bytes"
  end

  def test_blank_callback_data_is_refused
    [ "", "   ", nil ].each do |blank|
      assert_raises(ArgumentError) { Telegrama::InlineKeyboard.callback("Ok" => blank) }
    end
  end

  # ===========================================================================
  # URLs — the classic mistake is a Rails _path helper instead of _url
  # ===========================================================================

  def test_http_https_and_tg_urls_are_accepted
    [ "http://example.com", "https://example.com", "tg://user?id=1" ].each do |url|
      assert Telegrama::InlineKeyboard.url("Abrir" => url).to_h
    end
  end

  def test_a_relative_path_is_refused_because_telegram_needs_an_absolute_url
    error = assert_raises(ArgumentError) do
      Telegrama::InlineKeyboard.url("Abrir" => "/admin/dashboard/users/1")
    end

    assert_includes error.message, "/admin/dashboard/users/1"
    assert_match(/absolute|http/i, error.message)
  end

  def test_blank_urls_are_refused
    [ "", "   ", nil ].each do |blank|
      assert_raises(ArgumentError) { Telegrama::InlineKeyboard.url("Abrir" => blank) }
    end
  end

  # ===========================================================================
  # Labels
  # ===========================================================================

  def test_a_blank_label_is_refused
    [ "", "   ", nil ].each do |blank|
      assert_raises(ArgumentError) { Telegrama::InlineKeyboard.url(blank => "https://example.com") }
    end
  end

  def test_labels_keep_their_emoji_and_accents_untouched
    # Button labels are NOT parsed as Markdown by Telegram, so nothing here
    # should be escaped on the way out — doing so would show literal
    # backslashes on the button face.
    keyboard = Telegrama::InlineKeyboard.url("🔗 Abrir la retirada (87,40 €)" => "https://example.com")

    assert_equal "🔗 Abrir la retirada (87,40 €)", keyboard.to_h[:inline_keyboard].first.first[:text]
  end

  # ===========================================================================
  # Empty keyboards — always a bug, and Telegram's own error does not say so
  # ===========================================================================

  def test_an_empty_row_is_refused
    assert_raises(ArgumentError) { Telegrama::InlineKeyboard.new.row }
    assert_raises(ArgumentError) { Telegrama::InlineKeyboard.new.row(url: {}) }
  end

  def test_a_keyboard_with_no_rows_knows_it_is_empty
    assert_predicate Telegrama::InlineKeyboard.new, :empty?
    refute_predicate Telegrama::InlineKeyboard.url("Abrir" => "https://example.com"), :empty?
  end

  def test_serializing_an_empty_keyboard_raises_and_points_at_the_guard
    error = assert_raises(ArgumentError) { Telegrama::InlineKeyboard.new.to_h }

    assert_includes error.message, "empty?"
  end

  # ===========================================================================
  # End to end: the keyboard reaches api.telegram.org intact
  # ===========================================================================

  def test_a_keyboard_passed_as_reply_markup_reaches_the_api
    setup_fresh_configuration
    keyboard = Telegrama::InlineKeyboard.new
      .row(url: { "Abrir la retirada" => "https://carhey.com/admin/dashboard/x" })
      .row(callback: { "👀 Lo veo yo" => "claim:x" })

    stub_telegram_success
    Telegrama::Client.new.send_message("Retirada retenida", reply_markup: keyboard)

    assert_requested(:post, /api\.telegram\.org\/bot.*\/sendMessage/) do |request|
      markup = JSON.parse(request.body).fetch("reply_markup")
      markup == {
        "inline_keyboard" => [
          [ { "text" => "Abrir la retirada", "url" => "https://carhey.com/admin/dashboard/x" } ],
          [ { "text" => "👀 Lo veo yo", "callback_data" => "claim:x" } ]
        ]
      }
    end
  end

  def test_a_plain_hash_reply_markup_still_works_unchanged
    # The builder is sugar, never a gate: hand-built markup predates it and
    # must keep working exactly as before.
    setup_fresh_configuration
    stub_telegram_success

    Telegrama::Client.new.send_message(
      "hola",
      reply_markup: { inline_keyboard: [ [ { text: "Abrir", url: "https://example.com" } ] ] }
    )

    assert_requested(:post, /api\.telegram\.org\/bot.*\/sendMessage/) do |request|
      JSON.parse(request.body).dig("reply_markup", "inline_keyboard", 0, 0, "text") == "Abrir"
    end
  end
end
