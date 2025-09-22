require_relative "../services/fid_services/feed_sources"

class FidController < ApplicationController
  def index
    # TODO: mover.
    urls = FidServices::FeedSources.urls
    @feed = []
    providers = urls.flat_map do |url|
      @feed += FidServices::FetchFeed.fetch(url)
      end
    @feed = order(@feed)
  end

  def order(feed)
    feed.sort_by { |x| x.published }.reverse
  end
end
