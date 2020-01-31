require 'webrick'
require 'driq'
require 'driq/webrick'
require 'drb'
require 'digest/md5'

class Koto
  def initialize(port, drb_url)
    @src = Driq::EventSource.new
    @svr = WEBrick::HTTPServer.new(:Port => port)

    @svr.mount_proc('/') do |req, res|
      on_index(req, res)
    end

    @svr.mount_proc('/stream') do |req, res|
      on_stream(req, res)
    end

    @svr.mount_proc('/news') do |req, res|
      on_news(req, res)
    end

    @front = {"src" => @src, 
              "webrick" => @svr, 
              "body" => File.read('koto.html')}
    DRb.start_service(drb_url, @front)
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

  def on_news(req, res)
    it = make_entry(req)
    @src.write(it)
    res.content_type = "text/plain"
    res.body = "i know";
  end

  Color = Hash.new do |h, k|
    md5 = Digest::MD5.new
    md5 << k.to_s
    r = 0b01111111 & md5.digest[0].unpack("c").first
    g = 0b01111111 & md5.digest[1].unpack("c").first
    b = 0b01111111 & md5.digest[2].unpack("c").first
    h[k] = sprintf("#%02x%02x%02x", r, g, b)
  end

  def make_entry(req)
    text = JSON.parse(req.body)["text"] || ""
    from = req["X-Forwarded-For"] || req.peeraddr[2]
    color = Color[from]
    group = [from, Time.now.strftime("%H:%M")].join(" @ ")
    {"text" => text, "group" => group, "color" => color}
  end

  def start
    @svr.start
  end
end

port = Integer(ENV['TOFU_PORT']) rescue 10510
drb_url = 'druby://localhost:55443'

koto = Koto.new(port, drb_url)
koto.start