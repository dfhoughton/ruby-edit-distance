# EditDistance

This is basically an implementation of the Levenshtein distance algorithm which lets you plug in your own cost calculations for
insertions, deletions, and substitutions which can vary by context. You can use this, for example, to make vowel harmony
rules, like `a -> ä` or `o -> ö` cheaper than other arbitrary substitutions, or to make suffix-related insertions and deletions cheaper
than word-medial modifications. The end result should be that, for an algorithm tuned to English, for example, the distance from `cat`
to `cats` would be short than that from `cat` to `chat`.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'edit_distance'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install edit_distance

## Synopsis

```ruby
require 'edit_distance'

lev = EditDistance.lev       # convenience method to use Levenshtein distance, EditDistance.levenshtein also works
lev.distance 'cat', 'cats'   # 1.0
lev.edits 'cat', 'cats'      # [ :same, :same, :same, :insertion ]
lev.explain 'cat', 'cats'    # [ "kept c (0.0)", "kept a (0.0)", "kept t (0.0)", "inserted s (1.0)" ]

# a new algorithm, identical to Levenshtein except all costs are 2
class TwiceAsGood < EditDistance::Scale
  def weigh( cell, edit, source_offset, destination_offset )
    2
  end
end

tag = EditDistance.analyzer TwideAsGood

tag.distance 'cat', 'cats'   # 2.0
```

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/edit_distance.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

