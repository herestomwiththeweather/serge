# Serge

A Ruby library to handle HTTP signatures for inbox deliveries on the Fediverse.

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add serge
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install serge
```

## Usage

There are 2 HTTP signature formats (draft-cavage and [RFC 9421](https://www.rfc-editor.org/info/rfc9421/)) in use on the Fediverse. `InboxDelivery` handles both formats with one interface.

For incoming messages, inside of a Rails controller method:

```ruby
begin
  inbox_delivery = Serge::InboxDelivery.new(request)
  key_id = inbox_delivery.key_id
  # public_key = YOUR_CODE_TO_RETRIEVE_PUBLIC_KEY_FROM_KEY_ID

  # verify the signature using the PEM-encoded RSA public key
  if inbox_delivery.verified?(public_key)
    # signature is valid
  else
    # signature is not valid
  end
rescue Serge::SignatureVerificationError => e
  # YOUR_CODE_TO_HANDLE_EXCEPTION
end
```

You can also set the logger in a Rails initializer like `config/initializers/serge.rb`:

```ruby
Serge::InboxDelivery.logger = Rails.logger
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/herestomwiththeweather/serge. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/herestomwiththeweather/serge/blob/main/CODE_OF_CONDUCT.md).

## Code of Conduct

Everyone interacting in the Serge project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/herestomwiththeweather/serge/blob/main/CODE_OF_CONDUCT.md).
