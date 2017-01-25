class FileWatcher
  # Constants
  BUFFER_LENGTH = 1024
  ENTER_STRING = "\n"

  attr_reader :file, :wait_until
  def initialize(file_path, wait_until = nil)
    @wait_until = wait_until || 1
    # Will be used to manipulate/read the data for printing updates
    @file = File.new(file_path, 'r')
  end

  # Steps taken
  #   1. First we create new temporary file object (say t1), so that if we change the
  #      position of the file it doesn't affect the original file position.
  #   2. We take the seeker of t1 to the position of the seeker of the original file
  #   3. From here, we start reading the file in the backward direction until we find
  #      n number of lines or we reach start of the file.
  #
  def recent_lines(number)
    # Will be used to manipulate/read the data for recent lines.
    file2 = File.new(file.path, 'r')
    file2.seek(0, IO::SEEK_END)
    original_file_position = file.pos
    buffer_string          = ""

    if file2.pos >= original_file_position
      if original_file_position < BUFFER_LENGTH
        file2.seek(0, IO::SEEK_SET)
        buffer_string = file2.read(original_file_position)
      else
        reading_offset = original_file_position - file2.pos - BUFFER_LENGTH
        file2.seek(reading_offset, IO::SEEK_END)
        loop do
          data = file2.read(BUFFER_LENGTH)
          break if data.empty? || buffer_string.count(ENTER_STRING) > number

          buffer_string = data + buffer_string
          buffer_allowed = [file2.pos, BUFFER_LENGTH].min
          file2.seek(-buffer_allowed, IO::SEEK_CUR)
        end
      end

      lines = buffer_string.split(ENTER_STRING)
      start_index = [number, lines.length].min
      lines[-start_index..-1]
    else
      raise 'Not possible'
    end
  end

  # It continuously fetches the data from the file (that is being updated)
  def updates
    file.seek(0, IO::SEEK_END)
    loop do
      sleep(wait_until)
      data = file.read
      yield data unless data.empty?
    end
  end
end
