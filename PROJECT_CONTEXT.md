# Fid - Project Context

## Overview
Fid is a Rails 8.0.1 application that aggregates RSS/Atom feeds into a personalized feed reader. It provides two views: a personal feed ("Feed") and a news aggregator ("News").

**Tech Stack:**
- Ruby 3.3.1
- Rails 8.0.1
- SQLite3 database
- Solid Cache, Solid Queue, Solid Cable (Rails 8 defaults)
- Feedjira for RSS/Atom parsing
- Faraday for HTTP requests

## Project Structure

### Controllers
- `FidController` - Handles the personal feed view
- `NewsController` - Handles the news aggregator view
- Both controllers use the `Paginatable` concern for pagination (50 items per page)

### Services (`app/services/fid_services/`)
- `FetchFeed` - Fetches and caches RSS/Atom feeds with HTTP conditional requests (ETags, Last-Modified)
- `FeedSources` - Loads feed URLs from YAML configuration files

### Configuration Files
- `config/sources.yaml` - Feed URLs for personal feed
- `config/news.yaml` - Feed URLs for news aggregator

### Caching Strategy
- **Feed XML**: Cached with configurable expiration (1 hour for news, 1 day for personal feeds)
- **HTTP Conditional Requests**: Stores ETags and Last-Modified headers to minimize bandwidth
- **Parsed Entries**: Cached feed entries to avoid re-parsing
- **Cache Keys**: Versioned format strings (e.g., `"entries:v1:%s" % url`)

### Pagination Implementation (Added 2025-12-25)

#### Architecture
- **Plain Rails** implementation (no external gems)
- **In-memory pagination** of combined feed arrays
- **50 items per page** for both views
- **Simple Previous/Next navigation**

#### Components
1. **Paginatable Concern** (`app/controllers/concerns/paginatable.rb`)
   - `paginate_array(array, page:, per_page:)` - Main pagination method
   - `normalize_page(page)` - Ensures valid page numbers (>= 1)
   - `calculate_total_pages(total_items, per_page)` - Calculates total pages
   - `build_pagination_result(...)` - Builds pagination metadata hash

2. **ApplicationHelper** (`app/helpers/application_helper.rb`)
   - `pagination_links(pagination, path_method)` - Renders Previous/Next links
   - `build_prev_link(pagination, path_method)` - Builds Previous link or disabled state
   - `build_next_link(pagination, path_method)` - Builds Next link or disabled state

3. **View Integration**
   - Both `fid/index.html.erb` and `news/index.html.erb` include:
     - Pagination CSS styling (centered, linked navigation)
     - `<%= pagination_links(@pagination, :fid_index_path) %>` or `:news_index_path`
     - Disabled state styling for unavailable navigation

4. **Controller Usage**
   ```ruby
   page = (params[:page] || 1).to_i
   @pagination = paginate_array(@feed, page: page, per_page: 50)
   @feed = @pagination[:items]
   ```

5. **Pagination Metadata**
   ```ruby
   {
     items: [],           # Paginated items
     current_page: 1,     # Current page number
     total_pages: 5,      # Total number of pages
     per_page: 50,        # Items per page
     total_items: 234,    # Total items in full array
     has_prev: false,     # Whether Previous link is available
     has_next: true       # Whether Next link is available
   }
   ```

#### Edge Cases Handled
- Invalid page numbers (negative, zero) → Normalized to page 1
- Page beyond total pages → Capped to last page
- Empty feed arrays → Shows single empty page
- Single page of results → No pagination controls displayed

## Error Handling
- Network timeouts: 5s timeout, 3s open timeout for Faraday
- Exception reporting: `report_exception(e)` logs to Rails.logger
- Safe defaults: Returns empty arrays `[]` on fetch failures
- HTTP 304 Not Modified: Returns cached entries

## Testing
- **Test Suite**: Minitest (Rails default)
- **Run all tests**: `bin/rails test`
- **Run single file**: `bin/rails test test/controllers/fid_controller_test.rb`
- **Run specific test**: `bin/rails test test/controllers/fid_controller_test.rb:4`

### Pagination Tests
- Default page (page 1) rendering
- Page parameter handling
- Invalid page numbers (negative, zero, beyond max)
- Response success for all scenarios

## Code Style
- **Rubocop Rails Omakase**: Inherited from `rubocop-rails-omakase`
- **String quotes**: Double quotes by default
- **Indentation**: 2 spaces (not tabs)
- **Module namespacing**: `module FidServices` for service classes
- **Service pattern**: Initialize with config, implement `#call` method
- **Named parameters**: Use `url:` syntax (e.g., `Faraday.new(url:)`)
- **Routes**: Use `resources :controller, only: %w[index]`

## Development Commands
```bash
# Start server
bin/dev                    # or bin/rails server

# Run tests
bin/rails test            # All tests
bin/rails test path/to/test.rb:4  # Specific test

# Linting
bin/rubocop               # Check style
bin/rubocop -a            # Auto-fix issues

# Security
bin/brakeman              # Security scan
```

## Deployment
- **Platform**: Kamal deployment (Docker-based)
- **Assets**: Propshaft asset pipeline
- **Server**: Puma web server
- **Thruster**: HTTP asset caching/compression for production

## Key Patterns

### Feed Fetching Flow
1. Controller requests feed from multiple URLs
2. `FetchFeed.new(expiration_time).call(url)` for each URL
3. Check cache for parsed entries
4. If cache miss, fetch with conditional headers (ETags, Last-Modified)
5. Handle 304 Not Modified or parse new feed with Feedjira
6. Cache XML, headers, and parsed entries
7. Return entries array

### Pagination Flow
1. Controller fetches all feeds from multiple sources
2. Combines and sorts all entries by published date (newest first)
3. Applies pagination: `paginate_array(@feed, page: page, per_page: 50)`
4. Extracts paginated items: `@feed = @pagination[:items]`
5. View renders items and pagination controls

## Recent Changes

### 2025-12-25: Pagination Implementation
- Added `Paginatable` concern for reusable pagination logic
- Updated `FidController` and `NewsController` with pagination (50 items/page)
- Created `pagination_links` helper for Previous/Next navigation
- Added pagination CSS styling to both views
- Comprehensive test coverage for pagination scenarios
- All tests passing (6 runs, 10 assertions, 0 failures)
- Rubocop compliant (0 offenses)

## Notes for AI Agents
- See `AGENTS.md` for build/lint/test commands and code style guidelines
- Always run tests after changes: `bin/rails test`
- Follow Omakase Ruby styling (enforced by Rubocop)
- Use concerns for shared controller logic
- Cache aggressively with versioned keys
- Handle network failures gracefully with safe defaults
- Report exceptions via `report_exception(e)` helper
