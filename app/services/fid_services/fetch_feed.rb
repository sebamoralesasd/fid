module FidServices
  class FetchFeed
    CACHE_XML = "xml:%s"
    CACHE_ETAG = "etag:%s"
    CACHE_LAST_MOD = "last_mod:%s"
    CACHE_ENTRIES= "entries:%s"

    def fetch(url)
      etag = Rails.cache.read(CACHE_ETAG % url)
      last_mod = Rails.cache.read(CACHE_LAST_MOD % url)
        conn = Faraday.new(url:) do |f|
          f.response :raise_error
          f.adapter Faraday.default_adapter
          f.options.timeout = 5
          f.options.open_timeout = 3
        end
        headers = {}
        headers["If-None-Match"] = etag if etag
        headers["If-Modified-Since"] = last_mod if last_mod
        response = conn.get(nil, nil, headers)

        if response.status == 304
          Rails.logger.info "Acá"
          Rails.cache.read(CACHE_ENTRIES % url)
        else
          xml = response.body
          Rails.cache.write(CACHE_XML % url, xml, expires_in: 30.minutes)
          Rails.cache.write(CACHE_ETAG % url, response.headers["etag"], expires_in: 30.minutes) if response.headers["etag"].present?
          Rails.cache.write(CACHE_LAST_MOD % url, response.headers["last-modified"], expires_in: 30.minutes) if response.headers["last-modified"].present?

          feed_data = Feedjira.parse(xml)
          entries = feed_data.entries
          Rails.logger.info "Última edición de #{feed_data.title}: #{feed_data.last_modified}"
          Rails.cache.write(CACHE_ENTRIES % url, entries, expires_in: 30.minutes)
          entries
        end
    rescue StandardError => e
      Rails.logger.error(e.inspect)
      return unless e.respond_to?(:backtrace) && e.backtrace.present?

      Rails.logger.error(e.backtrace.join("\n"))
      Rails.logger.error("StandardError: #{e.message}")
    end
  end
end
