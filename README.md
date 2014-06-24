# I18n assets

Ever wanted to use rails localization helpers inside your assets? Your dream just came true!

## Installation

Add this line to your application's Gemfile:

    gem 'i18n-assets'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install i18n-assets

## Usage

Just add `.erb` extension to your `.js` and `.css` files and use standard I18n helpers inside your files.

On assets precompilation localized versions of your files will be generated.

If you need to prevent `.js.erb` or `.css.erb` files from caching, you can add `config.assets.prevent_caching = true` to the `environments/development.rb` file.

## Example

You can check an example usage here: https://github.com/maximgladkov/localized_assets_precompilation_example_app

## Contributing

1. Fork it ( http://github.com/<my-github-username>/i18n-assets/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
