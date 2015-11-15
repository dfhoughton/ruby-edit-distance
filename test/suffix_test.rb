require 'test_helper'
require 'pry'

class SuffixAlgorithm < EditDistance::Scale
  def suffix_insertion? cell, o, w=cell.destination
    c = w[o-1]
    if c.hash[:suffix]
      0.25
    elsif cell.parent && suffix_insertion?(cell.parent, cell.d, w)
      0
    end
  end

  def suffix_deletion? cell, o, w=cell.source
    c = w[o-1]
    if c.hash[:suffix]
      0.25
    elsif cell.parent && suffix_deletion?(cell.parent, cell.s, w)
      0
    end
  end

  def weigh parent, edit, s, d
    if edit == :deletion && w = suffix_deletion?( parent, s )
      w
    elsif edit == :insertion && w = suffix_insertion?( parent, d )
      w
    else
      1
    end
  end

  def prepare matrix
    [/ing$/i, /ed$/i, /(?<=e)d$/i, /s$/i, /en$/i, /(?<=e)n$/i].each do |rx|
      [matrix.source, matrix.destination].each do |w|
        if o = ( w.to_s =~ rx )
          w[o].hash[:suffix] = true
        end
      end
    end
  end
end

class EditDistanceTest < Minitest::Test
  def e
    EditDistance.analyzer SuffixAlgorithm
  end

  def test_alg_1
    assert_equal 0.25, e.distance( 'cat', 'cats' )
  end
end
