require 'test_helper'
require 'pry'

class EditDistanceSimpleSuffixTest < Minitest::Test
  class SimpleSuffixAlgorithm < EditDistance::Scale
    def initialize offset
      @offset = offset
    end

    def suffixy? word, i
      true if ( c = word[i-1] ) && c.back? && c.post < @offset
    end

    def weigh parent, edit, s, d
      if edit == :deletion && suffixy?( parent.source, s )
        0.25
      elsif edit == :insertion && suffixy?( parent.destination, d )
        0.25
      elsif edit == :substitution && suffixy?( parent.source, s ) && suffixy?( parent.destination, d )
        0.25
      else
        1
      end
    end
  end

  def e
    EditDistance.analyzer SimpleSuffixAlgorithm.new 4
  end

  def test_alg_1
    assert_equal 0.25, e.distance( 'cat', 'cats' )
  end

  def test_alg_1
    assert_equal 0.25, e.distance( 'cats', 'cat' )
  end

  def test_no_morphemes
    assert_equal 1, e.distance( 'cat', 'chat' )
  end

  def test_on_and_off
    assert_equal 0.25, e.distance( 'bates', 'bated' )
  end
end
