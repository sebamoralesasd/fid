module FidServices
  class FetchFeed
    CACHE_VERSION = "v3"
    MAX_ENTRIES = 40
    STALE_TTL = 7.days
    Item = Data.define(:id, :title, :url, :author, :published)
    CACHE_ETAG = "etag:#{CACHE_VERSION}:%s"
    CACHE_LAST_MOD = "last_mod:#{CACHE_VERSION}:%s"
    CACHE_ENTRIES = "entries:#{CACHE_VERSION}:%s"
    CACHE_FRESH = "fresh:#{CACHE_VERSION}:%s"

    def initialize(expiration_time = 1.hour)
      @expiration_time = expiration_time
      @connections = Concurrent::Map.new
    end

    def call(url)
      data = from_cache(url)
      return data unless data.nil?

      fetch(url)
    end

    private

    def from_cache(url)
      return unless Rails.cache.exist?(CACHE_FRESH % url)

      Rails.cache.read(CACHE_ENTRIES % url)
    end

    def mark_fresh(url)
      Rails.cache.write(CACHE_FRESH % url, true, expires_in: @expiration_time)
    end

    def connection_for(url)
      @connections.compute_if_absent(url) do
        Faraday.new(url:) do |f|
          f.response :raise_error
          f.adapter Faraday.default_adapter
          f.options.timeout = 5
          f.options.open_timeout = 3
        end
      end
    end

    def to_items(entries)
      now = Time.now.utc
      entries.first(MAX_ENTRIES).map do |e|
        Item.new(id: e.id, title: e.title, url: e.url, author: e.author, published: e.published || now)
      end
    end

    def fetch(url)
      response = request(url)
      return not_modified(url) if response.status == 304

      store_validators(url, response.headers)
      store_items(url, parse(response.body))
    rescue StandardError => e
      report_exception e
      []
    end

    def not_modified(url)
      Rails.logger.debug "Status 304 not modified at #{url}"
      mark_fresh(url)
      Rails.cache.read(CACHE_ENTRIES % url) || []
    end

    def store_items(url, items)
      Rails.cache.write(CACHE_ENTRIES % url, items, expires_in: STALE_TTL)
      mark_fresh(url)
      items
    end

    def request(url)
      connection_for(url).get(nil, nil, conditional_headers(url))
    end

    def conditional_headers(url)
      return {} unless Rails.cache.exist?(CACHE_ENTRIES % url)

      {
        "If-None-Match" => Rails.cache.read(CACHE_ETAG % url),
        "If-Modified-Since" => Rails.cache.read(CACHE_LAST_MOD % url)
      }.compact
    end

    def store_validators(url, headers)
      write_header(CACHE_ETAG % url, headers["etag"])
      write_header(CACHE_LAST_MOD % url, headers["last-modified"])
    end

    def write_header(key, value)
      Rails.cache.write(key, value, expires_in: STALE_TTL) if value.present?
    end

    def parse(xml)
      feed_data = Feedjira.parse(xml)
      Rails.logger.info "Última edición de #{feed_data.title}: #{feed_data.last_modified}" if feed_data
      to_items(feed_data&.entries || [])
    end
  end
end
