# 💬 `telegrama` – a tiny wrapper to send admin Telegram messages

[![Gem Version](https://badge.fury.io/rb/telegrama.svg)](https://badge.fury.io/rb/telegrama)

> [!TIP]
> **🚀 Ship your next Rails app 10x faster!** I've built **[RailsFast](https://railsfast.com)**, a production-ready Rails boilerplate template that comes with everything you need to launch a software business in days, not weeks.

`telegrama` lets you send quick, simple admin / logging Telegram messages via a Telegram bot.

Useful for Rails developers using Telegram messages for notifications, admin alerts, errors, logs, daily summaries, and status updates, like:

```ruby
Telegrama.send_message("Important admin notification!")
```

I use it all the time to alert me of new sales, important notifications, and daily summaries, like this:

> 💸 **New sale!**
> 
> joh...e@gmail.com paid **$49.99** for Business Plan.
> 
> 📈 MRR: $12,345
> 
> 📈 Total customers: 1,234
> 
> [🔗 View purchase details](https://example.com/admin/subscriptions/123)

Which is a beautifully formatted message you'll in Telegram with only this:

```ruby
message = <<~MSG
  💸 *New sale\!* 
  
  #{customer.email} paid *$#{amount}* for #{product.name}\.
  
  📈 MRR: $#{Profitable.mrr}
  📈 Total customers: $#{Profitable.total_customers}
  
  [🔗 View purchase details](#{admin_subscription_url(subscription)})
MSG

Telegrama.send_message(message, formatting: { obfuscate_emails: true })
```

Note how the email gets redacted automatically to avoid leaking personal information (`john.doe@gmail.com` -> `joh...e@gmail.com`)

The gem sanitizes weird characters, you can also escape Markdown, HTML, etc.

For the MRR and revenue metrics you can use my gem [`profitable`](https://github.com/rameerez/profitable); and if you have different group chats for marketing, management, etc. you can send different messages with different information to each of them:

```ruby
Telegrama.send_message(a_general_message, chat_id: general_chat_id)
Telegrama.send_message(marketing_message, chat_id: marketing_chat_id)
```

The goal with this gem is to provide a straightforward, no-frills, minimal API to send Telegram messages reliably for admin purposes, without you having to write your own wrapper over the Telegram API.

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
  
  # Optional prefix/suffix for all messages (useful to identify messages from different apps or environments)
  config.message_prefix = nil  # Will be prepended to all messages if set
  config.message_suffix = nil  # Will be appended to all messages if set
  
  # Default formatting options
  config.formatting_options = {
    escape_markdown: true,    # Escape markdown special characters
    obfuscate_emails: false,  # Off by default, enable if needed (it anonymizes email addresses in the message to things like abc...d@gmail.com)
    escape_html: false,       # Optionally escape HTML characters
    truncate: 4096            # Truncate if message exceeds Telegram's limit (or a custom limit)
  }

  # HTTP client options
  config.client_options = {
    timeout: 30,               # HTTP request timeout in seconds (default: 30s)
    retry_count: 3,            # Number of retries for failed requests (default: 3)
    retry_delay: 1             # Delay between retries in seconds (default: 1s)
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

### Message Prefix and Suffix

You may have multiple applications sending messages to the same Telegram group chat, and it can be hard to identify which message came from which application. Using message prefixes and suffixes, you can easily label messages from different sources:

```ruby
# Label which environment this message is coming from
config.message_prefix = "[#{Rails.env}] \n"

# Or for different applications:
config.message_prefix = "[🛍️ Shop App] \n"
config.message_suffix = "\n--\nSent from Shop App"

config.message_prefix = "[📊 Analytics] \n"
config.message_suffix = "\n--\nSent from Analytics"
```

This way, when multiple applications send messages to the same chat, you'll see:
```
[🛍️ Shop App] 
New order received: $99.99
--
Sent from Shop App

[📊 Analytics] 
Daily Report: 150 new users today
--
Sent from Analytics
```

Both `message_prefix` and `message_suffix` are optional and can be used independently. They're particularly useful for:
- Distinguishing between staging and production environments
- Identifying messages from different microservices
- Adding environment-specific tags or warnings
- Including standardized footers or timestamps

### `send_message` options

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

- **`client_options`**
  *A hash that overrides the default HTTP client options for this specific request.*
  - `timeout` (Integer): Request timeout in seconds.
  - `retry_count` (Integer): Number of times to retry failed requests.
  - `retry_delay` (Integer): Delay between retry attempts in seconds.
  
  **Usage Example:**
  ```ruby
  Telegrama.send_message("URGENT: Server alert!", client_options: { timeout: 5, retry_count: 5 })
  ```

### Asynchronous message delivery

For production environments or high-traffic applications, you might want to offload message delivery to a background job. Our gem supports asynchronous delivery via ActiveJob.

With `deliver_message_async` setting enabled, calling:
```ruby
Telegrama.send_message("Hello asynchronously!")
```

will enqueue a job on the specified queue (`deliver_message_queue`) rather than sending the message immediately.

### HTTP client options

Telegrama allows configuring the underlying HTTP client behavior for API requests:

```ruby
Telegrama.configure do |config|
  # HTTP client options
  config.client_options = {
    timeout: 30,     # Request timeout in seconds (default: 30s)
    retry_count: 3,  # Number of retries for failed requests (default: 3)
    retry_delay: 1   # Delay between retries in seconds (default: 1s)
  }
end
```

These options can also be overridden on a per-message basis:

```ruby
# For time-sensitive alerts, use a shorter timeout and more aggressive retries
Telegrama.send_message("URGENT: Server CPU at 100%!", client_options: { timeout: 5, retry_count: 5, retry_delay: 0.5 })

# For longer messages or slower connections, use a longer timeout
Telegrama.send_message(long_report, client_options: { timeout: 60 })
```

Available client options:
- **`timeout`**: HTTP request timeout in seconds (default: 30s)
- **`retry_count`**: Number of times to retry failed requests (default: 3)
- **`retry_delay`**: Delay between retry attempts in seconds (default: 1s)

## Robust message delivery with fallback cascade

Telegrama implements a sophisticated fallback system to ensure your messages are delivered even when formatting issues occur:

### Multi-level fallback system

1. **Primary Attempt**: First tries to send the message with your configured formatting (MarkdownV2 by default)
2. **HTML Fallback**: If MarkdownV2 fails, automatically converts and attempts delivery with HTML formatting
3. **Plain Text Fallback**: As a last resort, strips all formatting and sends as plain text
4. **Emergency Response**: Even if all delivery attempts fail, your application continues running without exceptions

This ensures that critical notifications always reach their destination, regardless of formatting complexities.

## Advanced formatting features

Telegrama includes a sophisticated state machine-based markdown formatter that properly handles:

- **Nested Formatting**: Correctly formats complex nested elements like *bold text with _italic_ words*
- **Code Blocks**: Supports both inline `code` and multi-line code blocks with language highlighting
- **Special Character Escaping**: Automatically handles escaping of special characters like !, ., etc.
- **URL Safety**: Properly formats URLs with special characters while maintaining clickability
- **Email Obfuscation**: Implements privacy-focused email transformation (joh...e@example.com)
- **Error Recovery**: Gracefully handles malformed markdown without breaking your messages

The formatter is designed to be robust even with complex inputs, ensuring your messages always look great in Telegram:

````ruby
# Complex formatting example that works perfectly
message = <<~MSG
  📊 *Monthly Report*

  _Summary of #{Date.today.strftime('%B %Y')}_

  *Key metrics*:
  - Revenue: *$#{revenue}*
  - New users: *#{new_users}*
  - Active users: *#{active_users}*

  ```ruby
  # Sample code that will be properly formatted
  def calculate_growth(current, previous)
    ((current.to_f / previous) - 1) * 100
  end
  ```

  🔗 [View full dashboard](#{dashboard_url})
MSG

Telegrama.send_message(message)
````

## Testing

The gem includes a comprehensive test suite.

To run the tests:

```bash
bundle install
bundle exec rake test
```

The test suite uses SQLite3 in-memory database and requires no additional setup.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/rameerez/telegrama. Our code of conduct is: just be nice and make your mom proud of what you do and post online.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
