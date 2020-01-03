require 'webrick'

module WEBrick
  class ChunkedStream
    def initialize(stream)
      @data = nil
      @cursor = 0
      @stream = stream
    end

    def next_chunk
      @stream.pop
    rescue
      raise EOFError
    end

    def close
      @stream.close
    end

    def readpartial(size, buf='')
      buf.clear
      unless @data
        @cursor = 0
        @data = next_chunk
        @data.force_encoding("ascii-8bit")
      end
      if @data.bytesize <= size
        buf << @data
        @data = nil
      else
        slice = @data.byteslice(@cursor, size)
        @cursor += slice.bytesize
        buf << slice
        if @data.bytesize <= @cursor
          @data = nil
        end
      end
      buf
    end
  end
end

if __FILE__ == $0
  require 'webrick'
  require 'driq'
  require 'drb'
  
  src = Driq::EventSource.new
  svr = WEBrick::HTTPServer.new(:Port => 8086)
  body = <<EOS
<!DOCTYPE html>
<html>
  <head>
    <title>SSE</title>
  </head>
  <body>
    <h1>It Works!</h1>
    <ul id="list">
    </ul>
  </body>
  <script>
  var evt = new EventSource('/stream');
  evt.onmessage = function(e) {
    var newElement = document.createElement("li");
    var eventList = document.getElementById('list');
  
    newElement.innerHTML = "message: " + e.data;
    eventList.appendChild(newElement);
  };
  </script>
</html>
EOS

  front = {"src" => src, "webrick" => svr, "body" => body}

  DRb.start_service('druby://localhost:54321', front)

  svr.mount_proc '/' do |req, res|
    res.body = front['body']
  end

  svr.mount_proc('/stream') {|req, res|
    last_event_id = req["Last-Event-ID"]
    res.content_type = 'text/event-stream'
    res.chunked = true
    res.body = WEBrick::ChunkedStream.new(Driq::EventStream.new(src, last_event_id))
  }
  svr.start
end