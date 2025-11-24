# Memory monitoring for production
# Logs memory usage every 5 minutes to help track consumption patterns

if Rails.env.production?
  Thread.new do
    loop do
      begin
        # Get memory usage in MB
        memory_mb = `ps -o rss= -p #{Process.pid}`.to_i / 1024
        Rails.logger.info "[MEMORY] Process #{Process.pid}: #{memory_mb} MB"
      rescue StandardError => e
        Rails.logger.error "[MEMORY] Failed to get memory stats: #{e.message}"
      end

      sleep 300 # Log every 5 minutes
    end
  end
end
