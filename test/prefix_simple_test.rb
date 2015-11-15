require 'test_helper'
require 'pry'

class EditDistanceSimplePrefixTest < Minitest::Test
  class SimplePrefixAlgorithm < EditDistance::Scale
    def initialize offset
      @offset = offset
    end

    def prefixy? word, i
      true if ( c = word[i-1] ) && c.front? && c.pre < @offset
    end

    def weigh parent, edit, s, d
      if edit == :deletion && prefixy?( parent.source, s )
        0.25
      elsif edit == :insertion && prefixy?( parent.destination, d )
        0.25
      elsif edit == :substitution && prefixy?( parent.source, s ) && prefixy?( parent.destination, d )
        0.25
      else
        1
      end
    end
  end

  def e
    EditDistance.analyzer SimplePrefixAlgorithm.new 4
  end

  def test_alg_1
    assert_equal 0.25, e.distance( 'cat', 'scat' )
  end

  def test_alg_1
    assert_equal 0.25, e.distance( 'scat', 'cat' )
  end

  def test_no_morphemes
    assert_equal 1, e.distance( 'cat', 'cato' )
  end

  def test_on_and_off
    assert_equal 0.25, e.distance( 'scat', 'zcat' )
  end
end
