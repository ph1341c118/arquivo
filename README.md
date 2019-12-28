# Arquivo

Processa documentos do condominio ph1341c118 para arquivo. Pode tambem segmentar PDFs e MINUTAS. Tendo os documentos em pastas separadas, pode ainda criar arquivos apropriados.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'arquivo'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install arquivo

## Usage

    $ arquivo mp3 MINUTA  # processa MINUTA criando pasta com segmentos para arquivo
    $ arquivo pdf EXTRATO # processa EXTRATO criando pasta com documentos para arquivo
    $ arquivo dir PASTA   # processa faturas/recibos/extratos/minutas e cria arquivos c118

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/arquivo.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
