class CleanoutSidekiqUniqueDigestsWorker
  include Sidekiq::Worker

  def perform
    Sidekiq.redis do |conn|
      conn.keys('uniquejobs:*').each do |key|
        conn.del(key)
      end
    end

    User.find_each { |u| u.update(sync_job_id: nil) }
  end
end
