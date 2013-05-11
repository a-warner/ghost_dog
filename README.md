# Ghost::Dog

Making method_missing easier to deal with since 2013...

## Installation

Add this line to your application's Gemfile:

    gem 'ghost_dog'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ghost_dog

## Usage

Check out the specs for full usage information.  Here are some quick examples:

Simple syntax:

```ruby
class Minimal
  include GhostDog

  ghost_method /^tell_me_(.+)$/ do |what_to_tell|
    what_to_tell.gsub('_', ' ')
  end
end
```

```sh
>> Minimal.new.tell_me_hello_world # "hello world"
```

More complex example, using the DSL version:

```ruby
class ComplexExample
  include GhostDog

  def names
    ['ishmael', 'dave']
  end

  ghost_method do
    match_with do |method_name|
      if match = method_name.match(/^call_me_(#{names.join('|')})$/)
        match.to_a.drop(1)
      end
    end

    respond_with do |name|
      "what's going on #{name}?"
    end
  end
end
```

```sh
>> ComplexExample.new.call_me_ishmael # "what's going on ishmael?"
>> ComplexExample.new.call_me_samuel # NoMethodError
```

Implementing a (fairly) complex example (using `detect_by` instead of `find_by`) as a duplicate of ActiveRecord's dynamic finders:

```ruby
class MyModel < ActiveRecord::Base
  class << self
    include GhostDog

    ghost_method do
      create_method false

      match_with do |method_name|
        cols = column_names.join('|')
        if match = method_name.match(/\Adetect_by_(#{cols})((?:_and_(?:#{cols}))*)\z/)
          [[match[1]] + match[2].split('_and_').select(&:present?)]
        end
      end

      respond_with do |*args|
        columns_to_find_by = args.shift
        unless args.length == columns_to_find_by.length
          raise ArgumentError, "Wrong number of arguments (#{args.length} for #{columns_to_find_by.length})"
        end

        where(Hash[columns_to_find_by.zip(args)])
      end
    end
  end
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
