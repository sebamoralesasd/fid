module FidServices
  class FetchFeed
    CACHE_VERSION = "v1"
    CACHE_ETAG = "etag:#{CACHE_VERSION}:%s"
    CACHE_LAST_MOD = "last_mod:#{CACHE_VERSION}:%s"
    CACHE_ENTRIES = "entries:#{CACHE_VERSION}:%s"

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
      Rails.cache.read(CACHE_ENTRIES % url)
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

    def fetch(url)
      etag = Rails.cache.read(CACHE_ETAG % url)
      last_mod = Rails.cache.read(CACHE_LAST_MOD % url)
      conn = connection_for(url)
      headers = {}
      headers["If-None-Match"] = etag if etag
      headers["If-Modified-Since"] = last_mod if last_mod
      response = conn.get(nil, nil, headers)

      if response.status == 304
        Rails.logger.debug "Status 304 not modified at #{url}"
        []
      else
        xml = response.body
        Rails.cache.write(CACHE_ETAG % url, response.headers["etag"],
                          expires_in: @expiration_time) if response.headers["etag"].present?
        Rails.cache.write(CACHE_LAST_MOD % url, response.headers["last-modified"],
                          expires_in: @expiration_time) if response.headers["last-modified"].present?

        feed_data = Feedjira.parse(xml)
        entries = feed_data&.entries || []
        Rails.logger.info "Última edición de #{feed_data&.title}: #{feed_data&.last_modified}" if feed_data
        Rails.cache.write(CACHE_ENTRIES % url, entries, expires_in: @expiration_time)
        entries
      end
    rescue StandardError => e
      report_exception e
      []
    end
  end
end
