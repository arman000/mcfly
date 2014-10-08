# Mcfly

Mcfly is a database table versioning system.  It's useful for tracking
and auditing changes to database tables.  It's also very easy to
access the state of Mcfly tables at any point in its history.

![](http://i.imgur.com/IG77ww0.jpg)

## Features

* All row versions are stored in the same table.

* Different row versions are accessed through scoping.

* Applications can use Mcfly to time-warp all tables to previous
  points in time.

* Table queries for points in time are symmetric. i.e. queries to
  access data in the present look just like queries available in any
  particular point in time.

* Implemented as database triggers.  So, the versioning system is
  language/platform agnostic.

## Installation

    $ gem install mcfly

Or add it to your `Gemfile`, etc.

## Usage

To create Mcfly enabled tables, they need to be created using
`Mcfly::McflyMigration` or `Mcfly::McflyAppendOnlyMigration` instead
of the usual `ActiveRecord::Migration`.

    class CreateSecurityInstruments < McflyAppendOnlyMigration
      def change
        create_table :security_instruments do |t|
          t.string :name, null: false
          t.string :settlement_class, limit: 1, null: false
        end
      end
    end

    class CreateMarketPrices < McflyMigration
      def change
        create_table :market_prices do |t|
          t.references :security_instrument, null: false
          t.decimal :coupon, null: false
          t.integer :settlement_mm, null: false
          t.integer :settlement_yy, null: false
          t.decimal :price
        end
      end
    end

These migrations add the necessary versioning triggers for INSERT,
UPDATE and DELETE operations.  The append-only migration disallows
updates.  As such, append-only Mcfly tables allow rows to be INSERTed
or DELETEed, but not modified.

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

The `has_mcfly` declaration provides the `mcfly_lookup` generator which scopes queries to the proper timeline.  Also, `mcfly_validates_uniqueness_of` is Mcfly's scoped version of ActiveRecord's `validates_uniqueness_of`.

## Setting/Finding Responsible Party For A Change
TODO: discuss using `current_user` method in `ApplicationController`. Also, setting `Mcfly.whodunnit`.

## Implementation

TODO

## Limitations/Requirements

Currently, Mcfly only works with PostgreSQL databases. The following
line must be added to the `postgresql.conf` file.  Mcfly uses the
PostgreSQL session variable `mcfly.whodunnit` to store the current
user id.

    custom_variable_classes = 'mcfly'

## History

The database table versioning mechanism used in Mcfly was originally
developed at [TWINSUN][]. It has since been modified and enhanced at
[PENNYMAC][].

## License

Mcfly has been released under the MIT license. Please check the
[LICENSE][] file for more details.

[license]: https://github.com/rubygems/rubygems.org/blob/master/MIT-LICENSE
[pennymac]: http://www.pennymacusa.com
[twinsun]: http://www.twinsun.com
