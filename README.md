# Poe Watch Ruby API

A Ruby wrapper around the [https://poe.watch/api](poe.watch API). It implements the same DSL you are used to when using `ActiveRecord` but doesn't require Rails at all.

Inspired by [https://github.com/klayveR/poe-watch-api](klayveR's poe-watch-api JS wrapper).

## Requirements

- Redis: 4.0+
- Ruby 2.3+

## Installation

```
gem install poe-watch-api
```

or add it to your `Gemfile`

```
gem 'poe-watch-api'
```

## Dependencies

This library has a dependency over `redis`. For it to work you need to have redis installed on your machine (and your server, in production, if using Heroku, you can use an addon like `rediscloud`).
We use `redis` because we need to cache the data from Poe Watch to avoid refetching all the items data to often (there are almost 30k items in PoE which is quite a lot). 

There are two ways of making this gem work with redis: 

- Set a global `$redis` variable.
Example:
```ruby
$redis = Redis.new

# In production for instance if you were to use rediscloud on heroku :
url = ENV["REDISCLOUD_URL"] # or whatever is the URL of your redis

if url
  $redis = Redis.new(:url => url)
end
```

- Provide your own instance of redis through `PoeWatch::Api.redis = Redis.new(YOUR_PARAMS)`
Example: 
```ruby
PoeWatch::Api.redis = Redis.new

# In production for instance, if you were to use rediscloud on heroku:
url = ENV["REDISCLOUD_URL"] # or whatever is the URL of your redis

if url
  PoeWatch::Api.redis = Redis.new(:url => url)
end
```

The total footprint of the data from PoeWatch API in redis is a bit less than **2 megabytes**. You can check the exact memory footprint in your redis by calling `PoeWatch::Api.memory_footprint`, the data will be displayed in kilobytes.
The default time to live (TTL) of the cache is 45 minutes.

## Usage

Here is a simple usage example:
```
# See the dependencies section
PoeWatch::Api.redis = Redis.new

# Non mandatory
PoeWatch::Api.refresh!(3600) # cache for 1 hour

PoeWatch::Item.find({ name: "Circle of Nostalgia }).price_for_league('Metamorph')
```

### Item

#### Get all item data

```ruby
PoeWatch::Item.all # => array of PoeWatch::Item objects
PoeWatch::Item.count  # => total number of items
```

#### Get multiple specific items 
```ruby
items = PoeWatch::Item.where(name: /circle/i) # Returns all items with a name containing "circle"

items.first.id # => 223
items.first.name # => "Hubris Circlet"
```

#### Find one specific item
```ruby
item = PoeWatch::Item.find(name: "Circle of Nostalgia") # Returns the item "Circle of Nostalgia"
item = PoeWatch::Item.find(name: /circle/i) # Returns the first item with a name containing "circle"

items.id # => 223
items.name # => "Hubris Circlet"
```

#### Item properties

All properties have an accessor you can use, e.g: `item.id`, `item.name`, `item.hardcore`. 
All boolean properties have an additionnal question mark accessor, e.g:  `item.hardcore?`.

| Name | Type | Description |
| --- | --- | --- |
| id | `number` | poe.watch ID |
| name | `string` | name |
| type | `string` | base type |
| frame | `number` | frame type |
| tier | `number` | map tier |
| lvl | `number` | level (e.g: gem level) |
| quality | `number` | quality (e.g: gem quality) |
| corrupted | `boolean` | is the item corrupted |
| links | `number` | links count |
| ilvl | `number` | item level |
| var | `string` | variations |
| relic | `number` | whether the item is a relic or not. `true` always sets `properties.frame` to `9` |
| icon | `string` | icon URL |
| category | `string` | item category |
| group | `string` | item category group |
| influences | `array` | conqueror influences |

### League

#### Get all league data

```ruby
PoeWatch::League.all # => array of PoeWatch::League objects
PoeWatch::League.count  # => total number of leagues
```

#### Get multiple specific leagues 
```ruby
leagues = PoeWatch::League.where(hardcore: false) # Returns all non hardcore leagues
leagues = PoeWatch::League.where(name: /metamorph/i) # You can use regular expressions or strings for your queries

leagues.first.name # => "Hardcore Metamorph"
leagues.first.hardcore? # => true
leagues.first.start? # => "2019-12-13T20:00:00Z"
```

#### Find one specific league
```ruby
league = PoeWatch::League.find(name: "Metamorph") # Return the non hardcore "Metamorph" league
league = PoeWatch::League.find(name: /metamorph/i) # Will return the first Metamorph league found

league.name # => "Metamorph"
league.hardcore? # => false
league.start? # => "2019-12-13T20:00:00Z"
```

#### League properties

All properties have an accessor you can use, e.g: `league.id`, `league.name`, `league.hardcore`. 
All boolean properties have an additionnal question mark accessor, e.g:  `league.hardcore?`.

| Name     | Type | Description    |
| -------- | --- | ---------------- |
|id        | `Integer` | poe.watch ID |
|name      | `String`  | name |
|display   | `String`  | display name |
|hardcore  | `Boolean`    | is hardcore |
|active    | `Boolean`    | is active |
|start     | `String`  | start date |
|end       | `String`  | end date |
|challenge | `Boolean`    | is a challenge league |
|event     | `Boolean`    | is an event league |
|upcoming  | `Boolean`    | is upcoming |

### Categories

#### Get all categories data

```ruby
PoeWatch::Categories.all # => array of PoeWatch::Category objects
PoeWatch::Categories.count  # => total number of categories
```

#### Get multiple specific categories 
```ruby
categories = PoeWatch::Category.where(name: /accessory/i) # You can use regular expressions or strings for your queries

categories.first.display # => "Accessories"
```

#### Find one specific category
```ruby
category = PoeWatch::Category.find(name: /accessory/i) # You can use regular expressions or strings for your queries

category.display # => "Accessories"
category.groups # => [#<OpenStruct id=1, name="amulet", display="Amulets">, ...]
category.groups.first.name # => "amulet"
```

#### Category properties

All properties have an accessor you can use, e.g: `category.name`, `category.groups`. 

| Name     | Type | Description    |
| -------- | --- | ---------------- |
|id        | `Integer` | poe.watch ID |
|name      | `String`  | name |
|display   | `String`  | display name |
|groups    | `Array<OpenStruct>`    | an array of item types that belongs to this category. Stored as OpenStructs so you can access them with the `.` syntax. A group has 3 attributes: `id`, `name` and `display` |

### API

```ruby
# Fetch all the data from poe.watch API and cache it for the next 45 minutes.
# You don't actually need to call this. It is automatically called when using `::find`, `::where`, `::all` or `::count`, and won't do anything if the cache already contains data. 
# Although beware that if you don't call it first, the first call to find/where/all/count every 45 minutes will take longer (around 2-4 seconds, there are quite a lot of items to fetch).
PoeWatch::Api.refresh! 
# You can also specify a cache TTL different than 45 minutes
PoeWatch::Api.refresh!(3600) # 1 hour cache

# If you need to force clear the cache, you can use 
PoeWatch::Api.clear!

# You can check if the cache has expired with 
PoeWatch::Api.has_expired?
# Or do the opposite with 
PoeWatch::Api.ready?
```

## Shortcomings

- Doing a find or where on an item will always take some time (1-2 seconds) because it has to traverse all ~30k objects from PoE to find your matches. This could probably be optimised but I haven't had the time to get around to do it. 
- No rate limiter set for the moment so when fetching a bunch of item prices you could hit the rate limiter of `poe.watch`. I'll add one at some point in the future if is needed or requested.

## Contribution

The code is well documented, using [tomdoc](http://tomdoc.org/), is you wish to contribute, raise an issue or fork this project and create a pull request :).

Most of the codebase is in `lib/api`, `lib/base` and `lib/item`.

## License

Licensed under WTFPL.
