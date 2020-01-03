require 'test-unit'
require 'driq'

class DriqEventTest<Test::Unit::TestCase
  def setup
    @src = Driq::EventSource.new
  end

  def test_write
    driq = Driq.new
    src = Driq::EventSource.new(driq)
    src.write(1)
    assert_equal([nil, 1], driq.read(0).last)
    key, buf = src.read(0)
    assert_equal(3, buf.lines.size)
    assert_equal("id: #{key}\n", buf.lines[0])
    assert_equal("data: 1\n", buf.lines[1])
    assert_equal("\n", buf.lines[2])
  end

  def test_ping
    @src.ping
    assert_equal([:ping, "ping"], @src.driq.read(0).last)
    @src.comment("keep, alive\nagain")
    assert_equal([:ping, "keep, alive"], @src.driq.readpartial(0, 2).last.last)
  end

  def test_event
    @src.event("hello", {"one" => 1.0})
    assert_equal(["hello", {"one" => 1.0}], @src.driq.read(0).last)
    key, buf = @src.read(0)
    assert_equal("event: hello\n", buf.lines[1])
    data = buf.lines[2]
    data['data: '] = ''
    assert_equal({"one" => 1.0}, JSON.parse(data))
    assert_equal("\n", buf.lines[3])
  end

  def test_first_line
    assert_equal("foo", @src.first_line("foo"))
    assert_equal("foo", @src.first_line("foo\n"))
    assert_equal("foo", @src.first_line("foo\nbar\nbaz"))
  end

end