require 'test-unit'
require 'driq'

class DriqTest<Test::Unit::TestCase
  class Timer
    def initialize
      @start = Time.now
    end

    def elapsed
      Time.now - @start
    end
  end

  def assert_elapsed(atleast)
    start = Timer.new
    yield
    assert(start.elapsed > atleast)
  end

  def setup
    @driq = Driq.new(5)
  end

  def test_empty
    key = @driq.write("hello")
    assert_equal([key, 'hello'], @driq.read(0))
    key2 = @driq.write("world")
    assert_equal([key, 'hello'], @driq.read(0))
    assert_equal([key2, 'world'], @driq.read(key))
  end

  def test_wait
    x = Thread.new do
      assert_elapsed(2) do
        k, v = @driq.read(0)
        k, v = @driq.read(k)
      end
    end
    sleep 1
    @driq.write("hello")
    sleep 1
    @driq.write("hello")
    x.join
  end

  def test_large_key
    key = @driq.write("hello")
    assert_equal("hello", @driq.read(0)[1])
    x = Thread.new do
      assert_elapsed(1) do
        assert_equal("world", @driq.read(key * 2)[1])
      end
    end
    sleep 1
    @driq.write("world")
    x.join
  end

  def test_last
    assert_equal(nil, @driq.last)
    @driq.write("hello")
    assert_equal("hello", @driq.last.last)
    @driq.write("world")
    assert_equal("world", @driq.last.last)
  end

  def test_close
    @driq.push("hello")
    assert_equal("hello", @driq.read(0)[1])
    x = Thread.new do
      assert_elapsed(1) do
        assert_raise(ClosedQueueError) do
          @driq.read(nil)
        end
      end
    end
    sleep 1
    @driq.close
    x.join
  end
end