# Agent Guidelines for Fid (Rails 8.0.1 / Ruby 3.3.1)

## Build/Lint/Test Commands
- Run all tests: `bin/rails test`
- Run single test file: `bin/rails test test/controllers/fid_controller_test.rb`
- Run specific test: `bin/rails test test/controllers/fid_controller_test.rb:4`
- Lint: `bin/rubocop` (auto-fix: `bin/rubocop -a`)
- Security check: `bin/brakeman`
- Start server: `bin/dev` or `bin/rails server`

## Code Style (Rubocop Rails Omakase)
- Follow Omakase Ruby styling inherited from `rubocop-rails-omakase`
- Use double quotes for strings by default
- Use 2-space indentation (not tabs)
- Module namespacing: Use `module FidServices` for service classes in `app/services/fid_services/`
- Service pattern: Initialize with config, implement `#call` method
- Named parameters: Use `url:` syntax for keyword arguments (e.g., `Faraday.new(url:)`)
- Routes: Use `resources :controller, only: %w[index]` for resource routes

## Error Handling & Logging
- Use `rescue StandardError => e` for broad exception catching
- Report exceptions via `report_exception e` (configured in initializers/exception_reporting.rb)
- Handle network timeouts (5s timeout, 3s open_timeout for Faraday)
- Use `Rails.logger.info/debug/error` for logging
- Return empty arrays `[]` as safe defaults on fetch failures

## Caching Patterns
- Use `Rails.cache.fetch(key, expires_in: 1.hour)` for read-through caching
- Cache keys: Use format strings like `"entries:#{VERSION}:%s" % identifier`
- Respect HTTP conditional requests: Store/check ETags and Last-Modified headers
- Default expiration: 1 hour for feeds, 1 day for aggregated content

## Dependencies
- RSS/Atom parsing: `feedjira`, HTTP client: `faraday`
- Caching: `solid_cache`, Background jobs: `solid_queue`
- Testing: `capybara`, `selenium-webdriver` for system tests
