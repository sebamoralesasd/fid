require "test_helper"

class FetchFeedTest < ActiveSupport::TestCase
  FEED = <<~XML
    <?xml version="1.0"?>
    <rss version="2.0"><channel><title>t</title>
      <item><title>a</title><link>http://x/a</link><guid>a</guid><pubDate>Mon, 01 Jan 2024 00:00:00 GMT</pubDate></item>
    </channel></rss>
  XML

  Response = Struct.new(:status, :headers, :body)
  URL = "http://x/feed".freeze

  setup do
    @original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
  end

  teardown { Rails.cache = @original_cache }

  def with_request(fetcher, handler)
    fetcher.define_singleton_method(:request, &handler)
    yield
  end

  test "a 304 after the entries went stale returns the cached entries" do
    fetcher = FidServices::FetchFeed.new(1.hour)

    first = with_request(fetcher, ->(_) { Response.new(200, { "etag" => "abc" }, FEED) }) { fetcher.call(URL) }
    assert_equal 1, first.size

    travel 2.hours do
      seen = nil
      probe = lambda do |url|
        seen = fetcher.send(:conditional_headers, url)
        Response.new(304, {}, "")
      end
      second = with_request(fetcher, probe) { fetcher.call(URL) }

      assert_equal({ "If-None-Match" => "abc" }, seen)
      assert_equal first, second
    end
  end

  test "a 304 renews freshness so the next call does not hit the network" do
    fetcher = FidServices::FetchFeed.new(1.hour)
    with_request(fetcher, ->(_) { Response.new(200, { "etag" => "abc" }, FEED) }) { fetcher.call(URL) }

    travel 2.hours do
      with_request(fetcher, ->(_) { Response.new(304, {}, "") }) { fetcher.call(URL) }
      never = ->(_) { flunk "unexpected request" }
      assert_equal 1, with_request(fetcher, never) { fetcher.call(URL) }.size
    end
  end
end
