if ENV["LOGTAIL_SOURCE_TOKEN"].present?
  Rails.logger = Logtail::Logger.create_default_logger(
    ENV["LOGTAIL_SOURCE_TOKEN"],
    ingesting_host: ENV["LOGTAIL_INGESTING_HOST"],
  )
end
