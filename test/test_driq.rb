require 'test-unit'
require 'driq'

class DriqTest<Test::Unit::TestCase
  def setup
    @driq = Driq.new(5)
  end

  def test_empty
    key = @driq.write("hello")
    assert_equal([key, 'hello'], @driq.read(0))
  end
end
