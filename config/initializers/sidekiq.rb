# frozen_string_literal: true

if Octobox.background_jobs_enabled?
  require 'sidekiq-scheduler'
  require 'sidekiq-status'

  Sidekiq.configure_server do |config|
    config.redis = { url: Octobox.config.redis_url }
    if Octobox.config.sidekiq_schedule_enabled?
      config.on(:startup) do
        Sidekiq.schedule = YAML.load_file(Octobox.config.sidekiq_schedule_path)
        Sidekiq::Scheduler.reload_schedule!
      end
    end
    Sidekiq::Status.configure_server_middleware config, expiration: 60.minutes
    Sidekiq::Status.configure_client_middleware config, expiration: 60.minutes

    config.death_handlers << ->(job, _ex) do
      SidekiqUniqueJobs::Digests.del(digest: job['unique_digest']) if job['unique_digest']
    end

    Sidekiq.default_worker_options = {
      lock_expiration: 10.minutes,
    }
  end

  Sidekiq.configure_client do |config|
    config.redis = { url: Octobox.config.redis_url }
    Sidekiq::Status.configure_client_middleware config, expiration: 60.minutes
  end

  if Rails.env.production?
    Sidekiq::Logging.logger.level = Logger::WARN
  end
end
