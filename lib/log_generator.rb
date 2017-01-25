class LogGenerator
  def self.generate(file_path, wait_until = nil)
    wait_until ||= 0.5
    index = 0
    loop do
      File.open(file_path, 'a') do |file|
        file.puts(" #{index} ---> #{Time.new}")
      end
      index += 1
      sleep(wait_until)
    end
  end
end
