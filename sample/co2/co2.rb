require 'webrick'
require 'driq'
require 'driq/webrick'
require 'mh-z19'

class CO2
  def initialize(port)
    @src = Driq::EventSource.new
    @svr = WEBrick::HTTPServer.new(:Port => port)

    @svr.mount_proc('/') do |req, res|
      on_index(req, res)
    end

    @svr.mount_proc('/stream') do |req, res|
      on_stream(req, res)
    end

    @front = {"src" => @src, 
              "webrick" => @svr, 
              "body" => File.read('co2.html')}
  end

  def on_index(req, res)
    res.body = File.read("co2.html")
  end

  def on_stream(req, res)
    last_event_id = req["Last-Event-ID"] || 0
    res.content_type = 'text/event-stream'
    res.chunked = true
    res.body = WEBrick::ChunkedStream.new(Driq::EventStream.new(@src, last_event_id))
  end

  def start
    Thread.new { co2_loop }
    @svr.start
  end

  def co2_loop
    co2 = MH_Z19::Serial.new('/dev/serial0')
    last = nil
    sleep 3
    loop do
      begin
        detail = co2.read_concentration_detail rescue nil
        @src.write(detail) unless last == detail
        last = detail
      rescue MH_Z19::Serial::InvalidPacketException
p $!
      end
      sleep 60
    end
  end
end

port = Integer(ENV['PORT']) rescue 8080

co2 = CO2.new(port)
co2.start
