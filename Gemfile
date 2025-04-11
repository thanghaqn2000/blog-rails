source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.0.0"

gem "rails", "~> 6.1.7", ">= 6.1.7.3"
gem "mysql2"
gem "paranoia"
gem "puma", "~> 5.0"
gem "sass-rails", ">= 6"
gem "webpacker", "~> 5.0"
gem "turbolinks", "~> 5"
gem "jbuilder", "~> 2.7"
gem "dotenv-rails"
gem "devise"
gem "devise-jwt"
gem "pry"
gem "rack-cors"
gem "representable"
gem "multi_json"
gem "config"
gem "ransack"
gem "kaminari", '~> 1.2'
gem "bootsnap", ">= 1.4.4", require: false

# Serializer
gem 'active_model_serializers', '~> 0.10.13'

group :development, :test do
  gem "byebug", platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  gem "web-console", ">= 4.1.0"
  gem "rack-mini-profiler", "~> 2.0"
  gem "listen", "~> 3.3"
  gem "spring"
  gem "factory_bot_rails"
  gem "faker"
end

group :test do
  gem "capybara", ">= 3.26"
  gem "selenium-webdriver", ">= 4.0.0.rc1"
  gem "webdrivers"
end

gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]
gem 'bcrypt', '~> 3.1.7'
