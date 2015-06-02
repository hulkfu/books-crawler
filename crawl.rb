require 'rest-client'

class Book
  HOST = "http://taiduoshu.com"
  RETRY_TIMES = 7

  def initialize(file_id)
    retry_times = 1
    begin
      @file_id = file_id
      url = "#{HOST}/file-#{@file_id}.html"
      puts "Fetch book #{@file_id} html..."
      @html = RestClient::Request.execute(url: url, method: :get).encode("UTF-8", "GBK") #force_encoding("GBK").encode("UTF-8")

      # get file key
      @key = %r!"downfile.php\?file_id=(.*)&file_key=(.+)\\\" onclick!.match(@html)[2]
      # get file title
      @title = %r!"file_tit(.*)/>(.+)</h3>!.match(@html)[2].strip
      @down_link = "#{HOST}/downfile.php?file_id=#{@file_id}&file_key=#{@key}"
      puts "Fetched: " + desc

    rescue StandardError => e   # Most is Encoding::InvalidByteSequenceError
      puts e
      retry_times += 1
      if retry_times <= RETRY_TIMES
        retry
      else
        log("error", "init")
      end
    end
  end

  def ready?
    instance_variable_defined?(:@down_link)
  end

  def download
    retry_times = 1
    begin
      puts "begin downloading #{@title}..."
      open("books/#{@title}", 'wb') do |file|
        file << RestClient::Request.execute(url: @down_link, method: :get)
      end
      puts "downloaded."
      log("sucess", "downloaded")
    rescue StandardError => e
      puts e
      retry_times += 1
      if retry_times <= RETRY_TIMES
        retry
      else
        log("error", "download")
      end
    end
  end

  def desc
    "#{@title}: #{@down_link} #{ready?}"
  end

  def log(file, info)
    open("#{file}.log", 'a') do |file|
      file.puts "#{info} #{@file_id} "
    end
  end

  class << self
    def crawl(start, finish)
      # mk books dir
      Dir.mkdir("books") unless File.exists?("books")
      start.to_i.step(finish.to_i, 1) do |i|
        file_id =  "%04d" % i
        book = Book.new file_id
        book.download if book.ready?
      end
    end

    def test(file_id)
      b = Book.new file_id
    end
  end
end

Book.crawl(ARGV[0], ARGV[1])
# Book.test ARGV[0]
