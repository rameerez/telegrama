# 💬 `telegrama` – a tiny wrapper to send admin Telegram messages

[![Gem Version](https://badge.fury.io/rb/telegrama.svg?v=0.1.1)](https://badge.fury.io/rb/telegrama?v=0.1.1)

Send quick, simple admin / logging Telegram messages via a Telegram bot.

I'm making this gem because I'm tired of copy-pasting the same Telegram wrapper from Rails project to Rails project just to send myself admin messages and notifications. The goal with this gem is to provide a straightforward, minimal API to send Telegram messages reliably. All I want to do is this:

```ruby
Telegrama.send_message("Important admin notification!")
```

This is useful for Rails developers using Telegram messages for notifications, admin alerts, errors, logs, daily summaries, and status updates.

## Quick start

Add telegrama to your Gemfile:

```ruby
gem 'telegrama'
```

Then run:

```bash
bundle install
```

Then, create an initializer file under `config/initializers/telegrama.rb` and set your credentials:

```ruby
Telegrama.configure do |config|
  config.bot_token = Rails.application.credentials.dig(Rails.env.to_sym, :telegram, :bot_token)
  config.chat_id   = Rails.application.credentials.dig(Rails.env.to_sym, :telegram, :chat_id)
  config.default_parse_mode = 'MarkdownV2'
  
  # Default formatting options
  config.formatting_options = {
    escape_markdown: true,    # Escape markdown special characters
    obfuscate_emails: false,  # Off by default, enable if needed (it anonymizes email addresses in the message to things like abc...d@gmail.com)
    escape_html: false,       # Optionally escape HTML characters
    truncate: 4096            # Truncate if message exceeds Telegram's limit (or a custom limit)
  }

  config.deliver_message_async = false           # Enable async message delivery with ActiveJob (enqueue the send_message call to offload message sending from the request cycle)
  config.deliver_message_queue = 'default'       # Use a custom ActiveJob queue
end
```

Done!

You can now send Telegram messages using your bot:

```ruby
Telegrama.send_message("Hey, this is your Rails app speaking via Telegram!")
```

## Advanced options

### Obfuscate emails in the message

Sometimes you want to report user actions including a sufficiently identifiable but otherwise anonymous user email. For example, when someone makes gets a refund, you may want to send a message like `john.doe21@email.com got refunded $XX.XX` – but there may be other people / employees in the group chat, so instead of leaking personal, private information, just turn on the `obfuscate_emails` option and the message will automatically get formatted as: `joh...1@email.com got refunded $XX.XX`

### Overriding defaults with options

You can pass an options hash to `Telegrama.send_message` to override default behavior on a per‑message basis:

- **`chat_id`**
  *Override the default chat ID set in your configuration.*
  **Usage Example:**
  ```ruby
  Telegrama.send_message("Hello, alternate group!", chat_id: alternate_chat_id)
  ```

- **`parse_mode`**
  *Override the default parse mode (default is `"MarkdownV2"`).*
  **Usage Example:**
  ```ruby
  Telegrama.send_message("Hello, world!", parse_mode: "HTML")
  ```

- **`disable_web_page_preview`**
  *Enable or disable web page previews (default is `true`).*
  **Usage Example:**
  ```ruby
  Telegrama.send_message("Check out this link: https://example.com", disable_web_page_preview: false)
  ```

- **`formatting`**
  *A hash that overrides the default formatting options provided in the configuration. Available keys include:*
  - `escape_markdown` (Boolean): Automatically escape Telegram Markdown special characters.
  - `obfuscate_emails` (Boolean): Obfuscate email addresses found in the message.
  - `escape_html` (Boolean): Escape HTML entities.
  - `truncate` (Integer): Maximum allowed message length (default is `4096`).
  
  **Usage Example:**
  ```ruby
  Telegrama.send_message("Contact: john.doe@example.com", formatting: { obfuscate_emails: true })
  ```

### Asynchronous message delivery

For production environments or high-traffic applications, you might want to offload message delivery to a background job. Our gem supports asynchronous delivery via ActiveJob.

With `deliver_message_async` setting enabled, calling:
```ruby
Telegrama.send_message("Hello asynchronously!")
```

will enqueue a job on the specified queue (`deliver_message_queue`) rather than sending the message immediately.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/rameerez/telegrama. Our code of conduct is: just be nice and make your mom proud of what you do and post online.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
