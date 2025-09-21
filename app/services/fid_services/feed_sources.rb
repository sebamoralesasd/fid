module FidServices
class FeedSources
  KEY = "rss:sources_yaml"

  def self.urls
    Rails.cache.fetch(KEY, expires_in: 1.hour) do
      YAML.safe_load(
        ERB.new(File.read(Rails.root.join("config/sources.yaml"))).result
      ).map { |h| h["url"].to_s }.uniq
    end
  end
end
end
