source 'http://rubygems.org'

gem 'rails', '~> 4.0.2'
gem 'bcrypt-ruby', require: 'bcrypt'
gem 'rails-observers'
gem 'actionpack-page_caching'

gem 'sqlite3'
gem 'mysql2'
gem 'pg'

gem 'redis', '~> 3.0.4'
gem 'hiredis', '~> 0.4.5'

gem 'therubyracer'
gem 'json'
gem 'sass-rails', '~> 4.0.0'
gem 'coffee-rails'
gem 'uglifier'
gem 'dynamic_form'
gem 'jquery-rails'
gem 'rails-backbone'

# Deploy with Capistrano
gem 'capistrano', '~> 2.15.4'

# To use debugger
# gem 'ruby-debug'

# OAuth
gem 'doorkeeper'#, '~> 0.7.2'

# OpenID gem. The stock gem is incompatible with Ruby 1.9, this fixes that.
gem 'ruby-openid', require: 'openid'

gem 'acts_as_list'

gem 'nokogiri'
gem 'daemon-spawn'

gem 'sunspot_rails', '2.0.0'
gem 'progress_bar'

gem 'newrelic_rpm', group: 'newrelic'

gem 'fastimage'
gem 'ruby-filemagic', require: 'filemagic'
gem 'aws-s3', require: 'aws/s3'
gem 'redcarpet', '~> 3.0'
gem 'rouge'
gem "font-awesome-rails", "~> 3.2.1"

group :development do
  gem 'yui-compressor', require: 'yui/compressor'
  gem 'guard'
  gem 'guard-spork'
  gem 'guard-rspec'
end

group :development_mac do
  gem 'rb-fsevent'
  gem 'ruby_gntp'
end

group :test do
  gem 'simplecov', require: false
end

group :test, :development do
  gem 'dotenv-rails'

  gem 'sunspot_solr', '2.0.0'
  gem 'sunspot-rails-tester'

  # RSpec
  gem 'rspec-rails'
  gem 'shoulda-matchers'
  gem 'json_spec'
  gem 'capybara'
  gem 'fuubar'

  # FactoryGirl
  gem 'factory_girl_rails'

  # Spork
  gem 'spork'
end