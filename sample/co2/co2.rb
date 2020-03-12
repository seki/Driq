require 'webrick'
require 'driq'
require 'driq/webrick'

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
              "body" => File.read('koto.html')}
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
    @svr.start
  end
end

port = Integer(ENV['PORT']) rescue 8080

co2 = CO2.new(port)
co2.start