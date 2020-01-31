require "driq/version"
require "monitor"
require "json"

class Driq
  include MonitorMixin

  def initialize(size=100)
    super()
    @last = 0
    @floor = size
    @ceil = size * 2
    @list = []
    @event = new_cond
    @closed = false
  end

  def write(value)
    synchronize do
      cell = [make_key, value]
      @list.push(cell)
      @list = @list.last(@floor) if @list.size > @ceil
      @event.broadcast
      return cell.first
    end
  end
  alias push write

  def read(key)
    readpartial(key, 1).first
  end

  def last(if_empty=nil)
    synchronize do
      @list.empty? ? if_empty : read(@last - 1)
    end
  end

  def last_key
    @last
  end

  def readpartial(key, size)
    synchronize do
      key = @last unless key
      raise ClosedQueueError if @closed
      idx = seek(key)
      if idx.nil?
        key = @last
        @event.wait
        idx = seek(key)
      end
      raise ClosedQueueError if @closed
      @list.slice(idx, size)
    end
  end

  def close
    synchronize do
      @closed = true; 
      @event.broadcast 
    end
  end

  private
  def make_key(time=Time.now)
    key = [time.tv_sec * 1000000 + time.tv_usec, @last + 1].max
  ensure
    @last = key
  end

  def seek(key)
    @list.bsearch_index {|x| x.first > key}
  end
end

class DriqDownstream < Driq
  def initialize(upper, size=100)
    super(size)
    @upper = upper
    Thread.new { download }
  end

  def write(value)
    @upper.write(value)
  end

  def download
    while true
      ary = @upper.readpartial(@last, @ceil)
      synchronize do
        @list += ary
        @list = @list.last(@floor) if @list.size > @ceil
        @last = ary.last[0]
        @event.broadcast
      end
    end
  end
end

class Driq
  class EventSource
    def initialize(driq = nil)
      @driq = driq || Driq.new
    end
    attr_reader :driq

    def write(value)
      @driq.write([nil, value])
    end

    def first_line(str)
      str.to_s.lines.first.chomp
    end

    def event(ev, value)
      @driq.write([first_line(ev), value])
    end

    def ping
      comment
    end

    def comment(str="ping")
      @driq.write([:ping, first_line(str)])
    end

    def build_packet(cursor, ev, value)
      case ev
      when :ping
        ": #{value}\n\n"
      when nil
        "id: #{cursor}\ndata: #{value.to_json}\n\n"
      else
        "id: #{cursor}\nevent: #{ev}\ndata: #{value.to_json}\n\n"
      end
    end

    def read(cursor)
      cursor, value = @driq.read(cursor)
      return cursor, build_packet(cursor, value[0], value[1])
    end
  end

  class EventStream
    def initialize(src, seek=nil)
      @src = src
      @cursor = Integer(seek) rescue (src.driq.last_key - 1)
    end

    def pop
      @cursor, buf = @src.read(@cursor)
      buf
    end

    def close; end
  end
end

