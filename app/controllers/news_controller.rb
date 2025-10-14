require_relative "../services/fid_services/feed_sources"

class NewsController < ApplicationController
  def index
    # TODO: mover.
    urls = FidServices::FeedSources.new.urls("news")
    @feed = []
    urls.flat_map do |url|
      @feed += FidServices::FetchFeed.new.call(url)
    end
    @feed = order(@feed)
  end

  def order(feed)
    feed.sort_by { |x| x.published }.reverse
  end
end
