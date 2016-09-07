require 'uploader/version'
require 'sneakers'
require 'sneakers/runner'
require 'aws-sdk'
require 'logger'

module Uploader

  def self.queue
    @@queue
  end

  def self.bucket
    @@bucket
  end

  def self.s3_client
    @@s3
  end

  def self.start(queue:, bucket:)
    @@queue = queue
    @@bucket = bucket

    Sneakers.configure(
      amqp: "amqp://#{ENV['RABBITMQ_USER']}:#{ENV['RABBITMQ_PASSWORD']}@#{ENV['RABBITMQ_HOST']}:#{ENV['RABBITMQ_PORT']}",
      daemonize: false,
      log: STDOUT,
      workers: 1,
      timeout_job_after: 60,
      threads: 10,
    )

    Sneakers.logger.level = Logger::INFO

    @@s3 = Aws::S3::Client.new(
        :access_key_id => ENV['S3_ACCESS_KEY'],
        :secret_access_key => ENV['S3_SECRET_KEY'],
        :region => ENV['S3_REGION'],
        :endpoint => "http://#{ENV['S3_HOST']}:#{ENV['S3_PORT']}/",
        :force_path_style => true)

    require 'uploader/worker'

    puts "Uploader starting. Listen queue: #{@@queue}. Upload bucket: #{@@bucket}"

    r = Sneakers::Runner.new([ Uploader::UploaderWorker ])
    r.run
  end
end
