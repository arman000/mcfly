# Mcfly

Mcfly is a database table versioning system.  It's useful for tracking
and auditing changes to database tables.

## Features

* All row versions are stored in the same table.

* Different row version are accessed through scoping.

* Applications can use Mcfly to time-warp all tables to previous
  states.
  
* Implemented as database triggers.  So, the versioning system is
  language/platform agnostic.

## Installation

    $ gem install mcfly

Or add it to your `Gemfile`, etc.

## Usage

To create Mcfly enabled tables, they need to be created using
`McFly::McFlyMigration` or `McFly::McFlyAppendOnlyMigration` instead
of the usual `ActiveRecord::Migration`.

    class CreateSecurityInstruments < McFlyAppendOnlyMigration
      def change
        create_table :security_instruments do |t|
          t.string :name, null: false
          t.string :settlement_class, limit: 1, null: false
        end
      end
    end

    class CreateMarketPrices < McFlyMigration
      def change
        create_table :market_prices do |t|
          t.references :security_instrument, null: false
          t.decimal :coupon, null: false
          t.integer :settlement_mm, null: false
          t.integer :settlement_yy, null: false
          # NULL indicates unknown price
          t.decimal :price
        end
      end
    end

These migration add the necessary versioning triggers for INSERT,
UPDATE and DELETE operations.  The append-only migration disallows
updates.  As such, append-only Mcfly tables rows to be INSERTed or
DELETEed, but not modified.

When you declare `has_mcfly` in your model, Mcfly adds some basic
functionality to the class.

    class SecurityInstrument < ActiveRecord::Base
      has_mcfly append_only: true

      attr_accessible :name, :settlement_class
      validates_presence_of :name, :settlement_class
      mcfly_validates_uniqueness_of :name
    
      mcfly_lookup :lookup, sig: 2 do
        |pt, name|
        find_by_name(name)
      end
    
      mcfly_lookup :lookup_all, sig: 1 do
        |pt| all
      end
    end

The `has_mcfly` declaration provides the `mcfly_lookup` generator
which is scopes queries to the proper timeline.  Also,
`mcfly_validates_uniqueness_of` is Mcfly's scoped version of
ActiveRecord's `validates_uniqueness_of`.

... TODO ... show examples of adding rows and accessing versions of
data ...

## Implementation

TODO

## Limitations

Currently, Mcfly only works with PostgreSQL databases.

## History

The database table versioning mechanism used in Mcfly was originally
developed at [TWINSUN][]. It has since been modified and enhanced at
[PENNYMAC][].

## License

Delorean has been released under the MIT license. Please check the
[LICENSE][] file for more details.

[license]: https://github.com/rubygems/rubygems.org/blob/master/MIT-LICENSE
[pennymac]: http://www.pennymacusa.com
[twinsun]: http://www.twinsun.com
