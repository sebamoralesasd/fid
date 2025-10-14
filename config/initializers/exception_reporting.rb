def report_exception(e)
      Rails.logger.error(e.inspect)
      return unless e.respond_to?(:backtrace) && e.backtrace.present?

      Rails.logger.error(e.backtrace.join("\n"))
      Rails.logger.error("StandardError: #{e.message}")
end
