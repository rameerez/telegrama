# frozen_string_literal: true

require "json"

module Telegrama
  # Inline keyboards: the buttons that hang under a message.
  #
  #   Telegrama.send_message(
  #     "Retirada retenida — necesita una persona",
  #     reply_markup: Telegrama::InlineKeyboard.url("Abrir la retirada" => withdrawal_url)
  #   )
  #
  # Several rows, chained — each `row` is one line of buttons on the phone:
  #
  #   keyboard = Telegrama::InlineKeyboard.new
  #     .row(url: { "Abrir la retirada" => withdrawal_url })
  #     .row(url: { "Cola de pagos" => queue_url, "Ficha" => user_url })
  #     .row(callback: { "👀 Lo veo yo" => "claim:#{id}" })
  #
  # Two kinds of button, and the difference matters:
  #
  #   • `url:`      opens a link. Nothing else is needed — this works with a
  #                 send-only bot, which is what this gem is.
  #   • `callback:` pings your bot with the given data when tapped. To RECEIVE
  #                 that tap you need a webhook (or long polling) handling
  #                 `callback_query` updates, which this gem deliberately does
  #                 not do. The button is built correctly either way; without a
  #                 receiver the tap simply spins and does nothing.
  #
  # Why a builder at all, when `reply_markup:` already accepts a plain Hash:
  # a malformed keyboard does not degrade into a message without buttons.
  # Telegram rejects the ENTIRE sendMessage, so the alert nobody could act on
  # is also the alert nobody received. Every check below turns one of those
  # silent, total failures into an ArgumentError at the call site, naming the
  # value that is wrong. Hand-built Hashes keep working exactly as before;
  # this is sugar, never a gate.
  class InlineKeyboard
    # Bot API: "Data to be sent back to the bot when the button is pressed,
    # 1-64 bytes". BYTES, not characters — one emoji is four of them, which is
    # how a label-ish callback payload silently blows the limit.
    # https://core.telegram.org/bots/api#inlinekeyboardbutton
    CALLBACK_DATA_MAX_BYTES = 64

    # Bot API: "HTTP or tg:// URL to be opened when the button is pressed".
    # A Rails `_path` helper instead of `_url` is the classic way to get this
    # wrong, and it is invisible until Telegram refuses the message.
    URL_SCHEMES = %r{\A(?:https?|tg)://}i

    def initialize
      @rows = []
    end

    class << self
      # One row, one kind, for the overwhelmingly common single-button case.
      #
      #   Telegrama::InlineKeyboard.url("Abrir" => "https://example.com")
      #   Telegrama::InlineKeyboard.callback("Lo veo yo" => "claim:42")
      def url(buttons) = new.row(url: buttons)
      def callback(buttons) = new.row(callback: buttons)
    end

    # One line of buttons. `url:` and `callback:` are both `{ label => value }`
    # hashes; within a row, url buttons render first, then callback ones, each
    # in its own hash order. Mix kinds freely — or call `row` twice when the
    # exact interleaving matters.
    def row(url: {}, callback: {})
      buttons = url.map { |label, target| url_button(label, target) } +
                callback.map { |label, data| callback_button(label, data) }

      if buttons.empty?
        raise ArgumentError,
          "Telegrama::InlineKeyboard#row needs at least one button — Telegram rejects an empty row."
      end

      @rows << buttons
      self
    end

    # True when nothing has been added yet. Build conditionally, then guard:
    #
    #   send_message(text, reply_markup: keyboard unless keyboard.empty?)
    def empty? = @rows.empty?

    def to_h
      if empty?
        raise ArgumentError,
          "Telegrama::InlineKeyboard is empty — Telegram rejects a keyboard with no buttons. " \
          "Add a row, or guard the send with `empty?`."
      end

      { inline_keyboard: @rows }
    end

    alias_method :as_json, :to_h

    # Client#perform_request nests this under `reply_markup` and dumps the
    # WHOLE payload in one `to_json` call, so the object has to serialize
    # itself or it lands as "#<Telegrama::InlineKeyboard…>".
    def to_json(*args) = to_h.to_json(*args)

    private

    def url_button(label, target)
      target = target.to_s
      unless target.match?(URL_SCHEMES)
        raise ArgumentError,
          "Telegrama::InlineKeyboard url button #{label.inspect} needs an absolute http(s):// or tg:// " \
          "URL, got #{target.inspect}. (A Rails `_path` helper is a relative path — use `_url`.)"
      end

      { text: presence!(label, "button label"), url: target }
    end

    def callback_button(label, data)
      data = presence!(data, "callback_data for button #{label.inspect}")
      if data.bytesize > CALLBACK_DATA_MAX_BYTES
        raise ArgumentError,
          "Telegrama::InlineKeyboard callback_data for button #{label.inspect} is #{data.bytesize} bytes, " \
          "over Telegram's #{CALLBACK_DATA_MAX_BYTES}-byte limit. (Emoji cost 4 bytes each — store the " \
          "payload server-side and put an opaque key here.)"
      end

      { text: presence!(label, "button label"), callback_data: data }
    end

    def presence!(value, what)
      string = value.to_s
      raise ArgumentError, "Telegrama::InlineKeyboard #{what} cannot be blank." if string.strip.empty?

      string
    end
  end
end
