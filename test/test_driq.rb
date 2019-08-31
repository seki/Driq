require 'test-unit'
require 'driq'

class DriqTest<Test::Unit::TestCase
  def setup
    @driq = Driq.new(5)
    p 1
  end

  def test_empty
    assert(false)
  end
end
