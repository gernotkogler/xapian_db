## 1.3.10 (March 2nd, 2023)

Fixes:

- Improved the code that reads the `xapian_db.yml` file to allow aliases in the yml file when using Ruby 3.1 or higher.

## 1.3.9 (October 26th, 2022)

Fixes:

- `XapianDb.execute_block` now uses `Thread.current[:xapian_db_block_writer]` to store its block-local writer as to avoid leaking into another Thread

## 1.3.8 (July 19th, 2021)

Fixes:

- xapian docs are deleted in the after commit hook in order to respect transaction rollbacks

## 1.3.7.4 (October 27th, 2020)

Changes:

- Instantiation of a BigDecimal using 'BigDecimal.new()' has been replaced with the new format 'BigDecimal() -- this is compatible with BigDecimal v1.4.x and v2.0.x AND drops support for BigDecimal v1.3.5'

**NOTE: Dropping support for BigDecimal v1.3.5 also drops the support of Ruby 2.2.x and earlier versions of Ruby.**

## 1.3.7.3 (November 30th, 2018)

Changes:

- add support for ruby > 2.3.x

## 1.3.7.2 (April 13th, 2018)

Changes:

- changed ownership

## 1.3.7.1 (March 3rd, 2018)

Changes:

- Allow access to configured blueprints through XapianDb::DocumentBlueprint

## 1.3.7 (January 12th, 2016)

Breaking Changes:

- search methods accept either a limit option OR page / per_page options, not both

Fixes:

- `XapianDb.database.delete_docs_of_class(klass)` now deletes docs of all descendants of `klass`, too (if tracked)

Changes:

- Ability to declare dependenices between blueprints
- Support for result ordering
- added a indexer preprocess callback to manipulate the terms that the indexer will index

## 1.3.6 (August 14th, 2015)

Changes:

- The required Ruby version is now 2.0.0 since we started using keyword parameters in method definitions
- Ability do define and handle dependencies between blueprints (see README)
- explicit order option for searches

## 1.3.5.4 (Jan 13th, 2015)

Fixes:

- path to database fixed in railtie
- fix for xapian > 1.2.15

## 1.3.5.3 (May 22th, 2014)

Fixes:

- retry the search when a Xapian::DatabaseModifiedError occurs

## 1.3.5.2 (January 3rd, 2014)

Fixes:

- total_pages are calculated correctly when a limit option is passed (Thanks, Jan)
- fix for will_paginate support

## 1.3.5.1 (August 16th, 2013)

Fixes:

- namespaced models work again with rails 4

## 1.3.5 (August 3rd, 2013)

Changes:

- Rails4 deprecation resolved
- licence information added tot the gemspec

## 1.3.4 (July 26th, 2013)

Changes:

- support for sidekiq queues

## 1.3.3.1 (June 23th, 2013)

Fixes:

- injected logical operators must be upper case in order to support Xapian::QueryParser::FLAG_BOOLEAN_ANY_CASE set to false

## 1.3.3 (June 23th, 2013)

Changes:

- xapian query parser flags are now configurable (see README)

Breaking Changes:

- enable_phrase_search config option is no longer supported (use config.enable_query_flag Xapian::QueryParser::FLAG_PHRASE instead)

## 1.3.2 (April 10th, 2013)

Changes:

- new no_split option for attributes and indexes; useful if you use a global term_splitter_count but want to disable splitting for
  a certain attribute

## 1.3.1 (February 25th, 2013)

Fixes:

- json codec handles nil values gracefully

## 1.3 (February 19th, 2013)

Breaking Changes:

- changed the internal serialization format for attributes; the new default is string, new codecs were added. YAML is not supported
  anymore, although you could implement a YAML-Codec on your own if you need it (see examples/custom_serialization.rb)

Changes:

- New option to enable / disable phrase search support
- term splitter option to boost "live queries" (see README)

## 1.2.5 (January 4th, 2013)

Changes:

- Define the min length a term must have to make it into the index (see README)
- define if a method should be indexed with its method name so you can do field searches (e.g. name:kogler); defaults to true

Fixes:

- query result creation optimized (lower memory footprint, better performance)

## 1.2.4.7 (December 17th, 2012)

Fixes:

- database reset removed since it has concurrency problems

## 1.2.4.6 (Decmber 17th, 2012)

Changes:

- progressbar gem replaced by ruby-progressbar
- XapianDb.rebuild_xapian_index resets the database to remove any stale index data

## 1.2.4.5 (July 19th, 2012)

Fixes:

- Fixes requiring the environment when calling rake. Prevented eg creation of the database using rake db:create

## 1.2.4.4 (May 30h, 2012)

Fixes:

- do not add attributes with null values to a document

## 1.2.4.3 (May 1st, 2012)

Fixes:

- handle null values on date and datetime attributes correctly

## 1.2.4.2 (May 1st, 2012)

Changes:

- access the attributes of a xapian document as a hash table (like active record)

## 1.2.4.1 (April 5th, 2012)

Fixes:

- better indexing for attributes containing arrays (index rebuild recommended)

## 1.2.4 (March 6th, 2012)

Features:

- Codec for DateTime objects added
- autoindex option for blueprints added

Fixes:

- the ActiveRecord after_commit hook must not reindex the object if it is a destroy action

## 1.2.3 (December 12th, 2011)

Changes:

- avoid eager loading of model classes in a rails app. The blueprint configuration file (xapian_blueprints.rb) caused all referenced classes
  to get loaded and parsed on every request. While not a problem in production environments, it could be a huge performance hit in development
  (especially when using the asset pipleline with many assets).
  The solution is based on the proof of concept by [Yves Senn](http://github.com/senny). Simply use symbols or strings instead of the classes in
  your xapian_blueprints.rb and wrap base_queries inside a block. See the README for updated informations on how to configure blueprints.
- added a rails example app using datamapper
- added a rake task to rebuild the index
- internal refactorings / optimizations

## 1.2.2.2 (November 29th, 2011)

Changes:

- removed dependency to xapian-ruby to allow custom installs of the xapian binaries (see chapter Installing xapian binaries in the README)

## 1.2.2.1 (November 22th, 2011)

Fixes:

- always use the correct table name for order clauses when indexing
- allow nil values for attributes declared :as => :date
- lazy load queue writers (beanstalk_writer, resque_writer) when needed

## 1.2.2 (November 15th, 2011)

Features:

- resultset accepts limit and paging options as strings
- added natural sort order option for blueprints (see README for details)

IMPORTANT: FULL INDEX REBUILD REQUIRED FOR THIS RELEASE!

## 1.2.1.1 (November 10th, 2011)

Fixes:

- resque writer wasn't loaded when beanstalk wasn't installed (thanks, javierv)

## 1.2.1 (November 9th, 2011)

Fixes:

- removed explicit dependency on resque

## 1.2.0 (November 8th, 2011)

Fixes:

- find_similar_to supports the :limit option

Features:

- new index worker / writer for resque (thanks, Michael)
- support for namespaced models (thanks, Albert)

## 1.1.4 (October 25th, 2011)

Fixes:

- removed loading of the deprecated rake task from the railtie

## 1.1.3 (October 24th, 2011)

Fixes:

- weight option for attributes and indexed values was not correctly applied

## 1.1.2 (September 10th, 2011)

Fixes:

- beanstalk_work flushes log messages (reinstall the worker script: rails generate xapian_db:install)

Features:

- massive performance optimization in rebuild_xapian_index

## 1.1.1 (September 9th, 2011)

Fixes:

- fixed a bug in XapianDb.rebuild_xapian_index that did not index all records of a klass; it ist highly recommended to run Xapian.rebuild_xapian_index after installing this version

Features:

- base query option for blueprints; may speed up reindexing signifiantly if you index associations

## 1.1 (September 7th, 2011)

Fixes:

- better handling of the beanstalk-client dependency
- recreate the xapian index database if the configured path exists but does not contain a valid xapian index
- support for non-integer primary keys (removed unneccesary to_i conversion)

Features:

- rails sample app upgraded to 3.1
- support for value range queries (strings, dates, numbers)
- sorting now works on a global query, too (XapianDb.search...)
- global factes queries have now the same options like class scoped facet queries
- Support for custom serialization into xapian documents; overwrite the serialization implementation in type_codec.rb or implement your own serialization for specific types (see examples/custom_serialization.rb)
- support to reindex a single object while evaluation an ignore_if block (if present)

IMPORTANT: YOU MUST REBUILD YOUR XAPIAN INDEX DATABASE SINCE THE INDEX STRUCTURE HAS CHANGED!

## 1.0 (August 17th, 2011)

Features:

- find similar documents based on one or more reference documents

## 0.5.15 (July 8th, 2011)

Features:

- faster install if the new, dependent gem containig xapian (xapian-ruby) is already installed

## 0.5.14 (July 7th, 2011)

Fixes:

- fixed an issue in the beanstalk worker (delete task could not retrieve the xapian id from an already deleted object)

## 0.5.13 (June 20th, 2011)

Fixes:

- handle attribute objects that return nil from to_s

Features:

- updated the xapian source to 1.2.6
- xapian source and build artefacts are removed after successful install
- added support for namespaced classes

## 0.5.12 (April 28th, 2011)

Fixes:

- avoid stale blueprint setups when an indexed class is reloaded

## 0.5.11 (April 21st, 2011)

Features:

- XapianDb.search accepts all options supported by XapianDb::Database.search
- Rails log entries include query execution time
- small changes to the beanstalk worker error handling

## 0.5.10 (April 6th, 2011)

Features:

- the beanstalk worker is now implemented as a daemon script (execute 'rails generate xapian_db:install' to install it)
- execute a block with auto indexing disabled (see 'Bulk inserts / updates / deletes' in teh README)
- updated the xapian source to version 1.2.5

## 0.5.9 (March 25th, 2011)

Fixes:

- indexing was broken in 0.5.8

## 0.5.8 (March 22th, 2011)

Fixes:

- automatic reindexing of a changed object now works when using beanstalk and the worker rake task

Features:

- support for transactions (see the README for details)

## 0.5.7 (March 7th, 2011)

Fixes:

- limit_value on the resultset is calculated again when the resultset is empty (thanks, Javi)
- added an order by id for rebuild_xapian_index to ensure that limit and offset work as expected

Features:

- option to specify a specific adapter for a blueprint overriding the global configuration

## 0.5.6 (February 28th, 2011)

Features:

- documents returned by a query have the new score property that reflects the match relevance in percent (1-100%)
- added compatibility to the kaminari pagination gem (thanks, Javi)
- added support for phrase searches (XapianDb.search('"this exact sentence"'))

## 0.5.5 (February 25th, 2011)

Fixes:

- ":memory:" as a configuration option for a database works again (was broken in 0.5.4)
- forcing utf-8 encoding on a spelling suggestion returned by the xapian query parser

Features:

- configure only those environments in xapian_db.yml where you want to override the defaults
- XapianDb.rebuild_xapian_index rebuilds the index for all blueprints

## 0.5.4 (February 22nd, 2011)

Fixes:

- relative database paths in the config file are resolved correctly when the Rails server is started as a daemon (-d)

Breaking Changes:

- the spelling suggestion of a query is now nil instead of an empty string if no suggestions were returned from xapian
- the resultset class (what you get back from a query) has been refactored for easier handling. See the README ("Process the results")
  for details

## 0.5.3 (February 15th, 2011)

Fixes:

- index blueprints can now handle inheritance. If a class does not have its own index blueprint,
  xapian_db uses the index blueprint from its super class (if defined)
- Added an ignore option to the blueprint definition to filter out objects that should not go into the index

## 0.5.2 (January 11th, 2011)

Features:

- xapian-core and xapian-ruby-bindings sources are now included and will be compiled and installed with the gem

## 0.5.1 (December 22th, 2010)

Features:

- simple facet support for indexed classes. Any attribute can be used in a facet search

Fixes:

- attribute names that match a Xapian::Document method are not allowed

## 0.5.0 (December 19th, 2010)

Features:

- beanstalk based index writer for production environments (multiple app instances, e.g. mongrel clusters,
  passenger...)

## 0.4.2 (December 17th, 2010)

Features:

- added a sample rails application to the repo
- added the id attribute for documents based on ActiveRecord and Datamapper objects

Changes:

- removed the language_method option from the blueprint configuration since it gives
  unpredictable results

Bugfixes:

- fixed the initialization error in a Rails app if there is no xapian_db.yml config file
- fixed the fallback to the global language when a model has an unsupported language and a
  language method is configured in the blueprint
- fixed an issue with yaml deserialization of ActiveRecord objects (only the attributes hash
  should be serialized)

## 0.4.1 (December 16th, 2010)

Bugfixes:

- fixed the handling of invalid page arguments in resultset.paginate. Invalid page arguments return
  an empty result set
- searches with an empty search expression do not raise an exception anymore and return an empty
  resultset

## 0.4.0 (December 15th, 2010)

Features:

- Simple facets implementation. The only facet supported is the class name of the indexed objects
- Support for sorting (only for class searches, not for global searches)
- The result of a search can be used with will_paginate

Bugfixes:

- removed the class scope expression from the spelling suggestion when searching on a class
- keys of the attributes and index hashes are now sorted to be compatible with ruby 1.8 (which does
  not preserve the order of the keys in a hash)
- Fixed the problem that blueprint configurations got lost after the first request in the development
  env (Rails only). You should put your blueprints either into a class that is loaded by Rails or into
  the file config/xapian_blueprints.rb wich is loaded automatically by XapianDb

**Since the internal structure of the index has changed, you must reindex your objects if you come from an
earlier version of XapianDb!**

## 0.3.4 (December 14th, 2010)

Features:

- perform searches on indexed classes to scope the search to objects of a specific class
- specify multiple blueprint attributes and index methods in one statement (without specifying options)
- use blocks for complex attribute or index specifications

Changes:

- changed the implementation of Resultset.size to get more accurate estimations
- changed the indexing of active_record or datamapper models when declared as attributes or indexes
  in a blueprint (indexes now all attributes of the object instead of using to_s)

## 0.3.3 (December 13th, 2010)

Features:

- Support for multi language stop words. The implementation was inspired by John Leachs xapian-fu gem
- Support for query spelling correction (similar to Google's 'did you mean...'). This feature is only
  available for persistent databases (due to a limitation of Xapian)

Changes:

- Languages must be configured by the iso language code (:en, :de, ...). No more support for the english
  language names (:english, :german, ...)
- Reduced the memory footprint when reindexing large tables

## 0.3.2 (December 10th, 2010)

Features:

- Moved the per_page option from Resultset.paginate to Database.search
- Added support for language settings (global and dynamic per object)
- Added support for xapian stemmers
- Removed the dependency to progressbar (but it is still used if available)
- Made the rebuild_xapian_index method silent by default (use :verbose => true to get status info)

## 0.3.1 (December 6th, 2010)

Bugfixes:

- Fixed the gemspec

## 0.3.0 (December 4th, 2010)

Features:

- Rails integration with configuration file (config/xapian_db.yml) and automatic setup

## 0.2.0 (December 1st, 2010)

Features:

- Blueprint configuration extended
- Adapter for Datamapper
- Search by attribute names
- Search with wildcards
- Document attributes can carry anything that is serializable by YAML

## 0.1.0 (November 23th, 2010)

Proof of concept, not really useful for real world usage
