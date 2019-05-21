# sequel_connection-guard
[![Build Status](https://travis-ci.org/umbrellio/sequel-connection_guard.svg?branch=master)](https://travis-ci.org/umbrellio/sequel-connection_guard)
[![Coverage Status](https://coveralls.io/repos/github/umbrellio/sequel-connection_guard/badge.svg?branch=master)](https://coveralls.io/github/umbrellio/sequel-connection_guard?branch=master)
[![Gem Version](https://badge.fury.io/rb/sequel-connection_guard.svg)](https://badge.fury.io/rb/sequel-connection_guard)

This Sequel extension provides a set of abstractions for working with databases that might not be
reachable at any given moment in time.

Goals:
- Allow to bootstrap an application when a database server is down
- Allow to safely and explicitly access a database
- In case connection fails, retry on next attempt

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sequel-connection_guard'
```

And then execute:
```sh
$ bundle
```

Enable the extension:
```ruby
Sequel.extension :connection_guard
```

## Usage

This extension provides two main abstractions for accessing unreliable databases. These are almost
identical, but one allows you to reach a database handle (instance of `Sequel::Database`) and
another allows you to reach a Sequel model (instance of `Sequel::Model`).

### Database guard

A database guard is what you use to access a database handle. First, you need to instantiate one:
```ruby
::DB = Sequel::DatabaseGuard.new('postgres://localhost/mydb')
```

There are two ways of using the guard.

#### Safe access

You can safely access the database handle by using `#safe_execute`:

```ruby
users = DB.safe_execute do
  # if the database is reachable
  alive do |db|
    db[:users].all
  end

  # if the database could not be reached. NOTE: this is optional
  dead do
    []
  end
end
```

#### Unsafe access

When you don't care about safety (or you're already inside a `safe_execute` context), use
`#force_execute`:

```ruby
users = DB.force_execute { |db| db[:users].all }
```

#### Accessing a raw database handle

Sometimes it's necessary to get access to a raw instance of `Sequel::Database` (for example, when
using the `database_cleaner` gem). You can get a raw handle like this:

```ruby
DB.raw_handle
```

Note that this will return `nil` if the database is unreachable.

### Model guard

A model guard is what you use to access a model handle. To create a model guard:
```ruby
# NOTE: `DB` must be an instance of Sequel::DatabaseGuard
User = Sequel::ModelGuard(DB[:users]) do
  one_to_many :cookies, class: 'Cookie::RawModel'

  def admin?
    role == 'admin'
  end
end
```

There are, again, two ways of using the guard.

#### Safe access

You can safely access the model by using `#safe_execute`:

```ruby
users = UserGuard.safe_execute do
  # if the database is reachable
  alive do |model|
    model.all
  end

  # if the database could not be reached. NOTE: this is optional
  dead do
    []
  end
end
```

#### Unsafe access

When you don't care about safety (or you're already inside a `safe_execute` context), use
`#force_execute`:

```ruby
users = UserGuard.force_execute { |model| model.all }
```

#### Accessing a raw model

Sometimes it's necessary to get access to a raw instance of `Sequel::Model` (good examples are
using this extension with `factory_bot` and describing associations like shown above).
To get the raw model:

```ruby
User = UserGuard::RawModel
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/umbrellio/sequel-connection_guard.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Authors
Created by [Alexander Komarov](https://github.com/akxcv).

<a href="https://github.com/umbrellio/">
  <img style="float: left;" src="https://umbrellio.github.io/Umbrellio/supported_by_umbrellio.svg" alt="Supported by Umbrellio" width="439" height="72">
</a>
