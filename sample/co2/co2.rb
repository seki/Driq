require 'webrick'
require 'driq'
require 'driq/webrick'
require_relative '../../../ruby-mh-z19/lib/mh-z19'

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
    res.body = @front["body"]
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
    sleep 30
    loop do
      begin
        detail = co2.read_concentration_detail rescue nil
        @driq.write(detail) unless last == detail
        last = detail
      rescue MH_Z19::Serial::InvalidPacketException
      end
    end
    sleep 10
  end
end

  end
end

port = Integer(ENV['PORT']) rescue 8080

co2 = CO2.new(port)
co2.start