## [Unreleased]

## [0.4.0] - 2026-09-18

- Added `Telegrama::InlineKeyboard`, a builder for the buttons that hang under
  a message: `Telegrama::InlineKeyboard.url("Open" => admin_url)` for the
  common single-button case, or `.row(url: {...}).row(callback: {...})` chained
  for several rows. Pass it straight to the existing `reply_markup:` option.
- Validates at the call site what Telegram would otherwise reject wholesale —
  a malformed keyboard fails the ENTIRE sendMessage rather than degrading to a
  message without buttons: `callback_data` over its 1-64 BYTE limit (bytes, not
  characters, so one emoji costs four), relative URLs (the Rails `_path` vs
  `_url` trap), blank labels, blank URLs, empty rows and empty keyboards.
- Documented `reply_markup:` and `reply_to_message_id:` in the README. Both
  were already forwarded to the Telegram API but had never been documented or
  covered by tests; hand-built `reply_markup` hashes keep working unchanged.
- Note on scope: `callback:` buttons build correctly, but RECEIVING a tap needs
  a webhook or long polling handling `callback_query` updates, which this gem
  deliberately does not do. It stays a send-only library.

## [0.3.1] - 2026-07-22

- Fixed MarkdownV2 escaping for `-` inside link text: the link-text escape
  class was missing the hyphen, so a label like `[GPS-risk](url)` reached
  Telegram unescaped — the API rejects the entire message ("Character '-' is
  reserved and must be escaped") and delivery fell back to unformatted plain
  text. The escape regex is now derived from `MARKDOWN_SPECIAL_CHARS` so the
  two can never drift apart again.

## [0.3.0] - 2026-05-22

- Added support for sending messages to Telegram forum topics with `message_thread_id`
- Added `config.message_thread_id` as an optional default forum topic for all messages
- Added per-message `message_thread_id:` overrides, including `message_thread_id: nil`
  to bypass a configured default topic for one send
- Preserved `message_thread_id` through async ActiveJob delivery, string-key serialized
  options, and Markdown-to-HTML-to-plain-text fallback retries
- Added validation so `message_thread_id` must be a positive integer when present
- Fixed `parse_mode: nil` to omit the `parse_mode` parameter from Telegram API
  requests instead of sending `null`
- Fixed plain-text sends so `parse_mode: nil` does not inherit MarkdownV2 or HTML
  escaping from configured formatting defaults
- Fixed HTML sends so they do not inherit MarkdownV2 escaping from configured
  formatting defaults
- Fixed MarkdownV2 escaping for underscores inside identifiers such as `is_bot`,
  `message_thread_id`, and `send_message`

## [0.2.0] - 2026-01-17

- Added Minitest test suite
- Fixed duplicate Error class definition causing conflicts
- Fixed missing `log_info` method
- Fixed `parse_mode: nil` handling to properly respect explicit nil override
- Fixed `strip_markdown` method to correctly strip markdown characters
- Fixed `retry_delay` validation to accept float values (e.g., 0.5 seconds)
- Added Ruby 3.5+ compatibility with `ostruct` dependency

## [0.1.3] - 2025-02-28

- Added client options for retries and timeout
- Added a more robust message parsing mechanism that fall backs from Markdown, to HTML mode, to plaintext if there are any errors
- Now parsing & escaping Markdown with a state machine
- Now we always send *some* message, even with errors -- Telegrama does not make a critical business process fail just because it's unable to properly format Markdown
- Added a test suite

## [0.1.2] - 2025-02-19

- Added optional message prefix and suffix configuration

## [0.1.1] - 2025-02-18

- Rebranded `telegrams` to `telegrama`

## [0.1.0] - 2025-02-18

- Initial release
