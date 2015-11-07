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

  class ED < EditDistance::Scale
    def weigh a,b,c,d
      2
    end
  end

  def test_class_constructor
    ed = EditDistance.analyzer ED
    assert_equal 2.0, ed.distance( 'cat', 'cats' )
  end
end
