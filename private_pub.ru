# Run with:
#   rackup private_pub.ru -s thin -E production -p8000
require 'bundler/setup'
require 'yaml'
require 'faye'
require 'private_pub'
require 'active_support/json'
require 'active_support/core_ext/object/json'
require_relative 'lib/file_watcher'
require_relative 'lib/log_generator'

Thread::abort_on_exception = true

# This thread block will keep populating the test.log file to get continuous logs.
log_file_path = File.expand_path('log/test.log')
FileUtils.touch(log_file_path) unless File.exist?(log_file_path)
Thread.new {
  LogGenerator.generate(log_file_path, 0.1)
}


#################################################################################

Faye::WebSocket.load_adapter('thin')
PrivatePub.load_config(File.expand_path('../config/private_pub.yml', __FILE__), ENV['RACK_ENV'] || 'production')


server = PrivatePub.faye_app(timeout: 90, extensions: [])
file_watcher = FileWatcher.new(log_file_path)

server.bind(:subscribe) do |client_id, channel_name|
  puts "I am subscribed to #{channel_name}"

  # Sends recent 10 lines of the log file to the subscriber on joining the channel
  Thread.new do
    recent_lines = file_watcher.recent_lines(10).join("<br>")
    PrivatePub.publish_to('/subscribe', { message: recent_lines }, false)
  end
end


# This thread block will keep monitoring the log file and will keep sending
# the latest updates in the file to all subscribers.
Thread.new {
  file_watcher.updates do |data|
    PrivatePub.publish_to('/general', { message: data.gsub("\n", "<br>")}, false)
  end
}

at_exit do
  puts "I am exiting"
end

run server