require_relative "../services/fid_services/feed_sources"

class NewsController < ApplicationController
  include Paginatable

  def index
    # TODO: mover.
    urls = FidServices::FeedSources.new.urls("news")
    fetcher = FidServices::FetchFeed.new(1.hour)
    threads = urls.map do |url|
      Thread.new do
        Rails.application.executor.wrap { fetcher.call(url) }
      end
    end
    @feed = order(threads.flat_map(&:value))

    page = (params[:page] || 1).to_i
    @pagination = paginate_array(@feed, page: page, per_page: 50)
    @feed = @pagination[:items]
  end

  def order(feed)
    feed.sort_by { |x| x.published }.reverse
  end
end
