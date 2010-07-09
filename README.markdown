Python's difflib for Ruby
=========================

Based on [this](http://rails-engines.rubyforge.org/rdoc/wiki_engine/classes/Diff/Utilities.html)
port of python's difflib. The port had 'XXX untested' for the get _ close _ matches function.

I added a get _ best _ match function, which simply returns the best result.

Documentation
-------------

The port code doesn't contain the detailed comments the python version has - maybe I should add them at some point.

Example
-------

(as in http://docs.python.org/library/difflib.html)

    irb> require 'rdifflib'
    => true
    irb> include Diff
    => Object
    irb> Diff.get_close_matches('appel', ['ape', 'apple', 'peach', 'puppy'], n=2, cutoff = 0.6)
    => ["apple", "ape"]
    irb> Diff.get_best_match('appel', ['ape', 'apple', 'peach', 'puppy'], cutoff = 0.6) 
    => "apple"

