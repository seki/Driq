require "driq/version"
require "monitor"

class Driq
  include MonitorMixin

  def initialize(max_size=100)
    super()
    @last = 0
    @max_size = max_size
    @list = []
    @event = new_cond
    @closed = false
  end

  def write(value)
    synchronize do
      cell = [make_key, value]
      @list.push(cell)
      @event.broadcast
      return cell.first
    end
  end

  def read(key)
    readpartial(key, 1).first
  end

  def last(if_empty=nil)
    synchronize do
      @list.empty? ? if_empty : read(@last - 1)
    end
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
    synchronize { 
      @closed = true; 
      @event.broadcast 
    }
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
