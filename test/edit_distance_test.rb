require 'test_helper'

class EditDistanceTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::EditDistance::VERSION
  end

  def edify s
    s.strip.split(/\s+/).map(&:to_sym)
  end

  def test_lev_cat_cat
    assert_equal 0, EditDistance.lev.distance('cat','cat')
  end

  def test_lev_cat_cat_edits
    assert_equal edify('same same same'), EditDistance.lev.edits('cat','cat')
  end

  def test_lev_cat_cats
    assert_equal 1, EditDistance.lev.distance('cat', 'cats')
  end

  def test_lev_cat_cats_edits
    assert_equal edify('same same same insertion'), EditDistance.lev.edits('cat', 'cats')
  end

  def test_lev_cat_chat
    assert_equal 1, EditDistance.lev.distance('cat', 'chat')
  end

  def test_lev_cat_chat_edits
    assert_equal edify('same insertion same same'), EditDistance.lev.edits('cat', 'chat')
  end

  def test_lev_cat_dog
    assert_equal 3, EditDistance.lev.distance('cat', 'dog')
  end

  def test_lev_cat_dog_edits
    assert_equal edify('substitution substitution substitution'), EditDistance.lev.edits('cat', 'dog')
  end

  def test_lambda_constructor
    ed = EditDistance::Analyzer.new -> (_,_,_,_) {1}
    assert_equal 1.0, ed.distance( 'cat', 'cats' )
  end

  def test_block_constructor
    ed = EditDistance::Analyzer.new do |_,_,_,_|
      1
    end
    assert_equal 1.0, ed.distance( 'cat', 'cats' )
  end

  class ED
    def self.weigh a,b,c,d
      1
    end
  end

  def test_class_constructor
    ed = EditDistance::Analyzer.new ED
    assert_equal 1.0, ed.distance( 'cat', 'cats' )
  end
end
