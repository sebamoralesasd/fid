module FidServices
class FeedSources
  KEY = "rss:%s"

  def urls(filename)
    Rails.cache.fetch(KEY % filename, expires_in: 1.hour) do
      YAML.safe_load(
        ERB.new(File.read(Rails.root.join("config/#{filename}.yaml"))).result
      ).map { |h| h["url"].to_s }.uniq
    end
  end
end
end
