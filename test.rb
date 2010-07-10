require 'test/unit'
require 'rdifflib'

include Diff

class DifflibTest < Test::Unit::TestCase
  # def setup
  # end

  # def teardown
  # end
    
  def test_empty
    m =  Diff.get_close_matches('appel', [], n=2, cutoff = 0.6)
    assert_equal([], m)
  end

  def test_number_matches
    m =  Diff.get_close_matches('appel', ['ape'], n=5, cutoff = 0.6)
    assert_equal(["ape"], m)
  end

  def test_matches
    m =  Diff.get_close_matches('appel', ['ape', 'apple', 'peach', 'puppy'], n=2, cutoff = 0.6)
    assert_equal(["apple", "ape"], m)
  end

  def test_best
    best =  Diff.get_best_match('appel', ['ape', 'apple', 'peach', 'puppy'], cutoff = 0.6)
    assert_equal('apple', best)
  end

  def test_quality
    best =  Diff.get_best_match('abc', %w[abc def gih], cutoff = 0.6)
    assert_equal("abc", best)
  end

  def test_quality2
    best =  Diff.get_best_match('abc', %w[def gih jkl], cutoff = 0.6)
    assert_equal(nil, best)
  end

end
