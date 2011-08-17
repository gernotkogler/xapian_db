##1.0 (August 17th, 2011)

Features:

  - find similar documents based on one or more reference documents

##0.5.15 (July 8th, 2011)

Features:

  - faster install if the new, dependent gem containig xapian (xapian-ruby) is already installed

##0.5.14 (July 7th, 2011)

Fixes:

  - fixed an issue in the beanstalk worker (delete task could not retrieve the xapian id from an already deleted object)

##0.5.13 (June 20th, 2011)

Fixes:

  - handle attribute objects that return nil from to_s

Features:

  - updated the xapian source to 1.2.6
  - xapian source and build artefacts are removed after successful install
  - added support for namespaced classes

##0.5.12 (April 28th, 2011)

Fixes:

  - avoid stale blueprint setups when an indexed class is reloaded

##0.5.11 (April 21st, 2011)

Features:

  - XapianDb.search accepts all options supported by XapianDb::Database.search
  - Rails log entries include query execution time
  - small changes to the beanstalk worker error handling

##0.5.10 (April 6th, 2011)

Features:

  - the beanstalk worker is now implemented as a daemon script (execute 'rails generate xapian_db:install' to install it)
  - execute a block with auto indexing disabled (see 'Bulk inserts / updates / deletes' in teh README)
  - updated the xapian source to version 1.2.5

##0.5.9 (March 25th, 2011)

Fixes:

  - indexing was broken in 0.5.8

##0.5.8 (March 22th, 2011)

Fixes:

  - automatic reindexing of a changed object now works when using beanstalk and the worker rake task

Features:

  - support for transactions (see the README for details)

##0.5.7 (March 7th, 2011)

Fixes:

  - limit_value on the resultset is calculated again when the resultset is empty (thanks, Javi)
  - added an order by id for rebuild_xapian_index to ensure that limit and offset work as expected

Features:

  - option to specify a specific adapter for a blueprint overriding the global configuration

##0.5.6 (February 28th, 2011)

Features:

  - documents returned by a query have the new score property that reflects the match relevance in percent (1-100%)
  - added compatibility to the kaminari pagination gem (thanks, Javi)
  - added support for phrase searches (XapianDb.search('"this exact sentence"'))

##0.5.5 (February 25th, 2011)

Fixes:

  - ":memory:" as a configuration option for a database works again (was broken in 0.5.4)
  - forcing utf-8 encoding on a spelling suggestion returned by the xapian query parser

Features:

  - configure only those environments in xapian_db.yml where you want to override the defaults
  - XapianDb.rebuild_xapian_index rebuilds the index for all blueprints

##0.5.4 (February 22nd, 2011)

Fixes:

  - relative database paths in the config file are resolved correctly when the Rails server is started as a daemon (-d)

Breaking Changes:

  - the spelling suggestion of a query is now nil instead of an empty string if no suggestions were returned from xapian
  - the resultset class (what you get back from a query) has been refactored for easier handling. See the README ("Process the results")
    for details

##0.5.3 (February 15th, 2011)

Fixes:

  - index blueprints can now handle inheritance. If a class does not have its own index blueprint,
    xapian_db uses the index blueprint from its super class (if defined)
  - Added an ignore option to the blueprint definition to filter out objects that should not go into the index

##0.5.2 (January 11th, 2011)

Features:

  - xapian-core and xapian-ruby-bindings sources are now included and will be compiled and installed with the gem

##0.5.1 (December 22th, 2010)

Features:

  - simple facet support for indexed classes. Any attribute can be used in a facet search

Fixes:

  - attribute names that match a Xapian::Document method are not allowed

##0.5.0 (December 19th, 2010)

Features:

  - beanstalk based index writer for production environments (multiple app instances, e.g. mongrel clusters,
    passenger...)

##0.4.2 (December 17th, 2010)

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

##0.4.1 (December 16th, 2010)

Bugfixes:

  - fixed the handling of invalid page arguments in resultset.paginate. Invalid page arguments return
    an empty result set
  - searches with an empty search expression do not raise an exception anymore and return an empty
    resultset

##0.4.0 (December 15th, 2010)

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

##0.3.4 (December 14th, 2010)

Features:

  - perform searches on indexed classes to scope the search to objects of a specific class
  - specify multiple blueprint attributes and index methods in one statement (without specifying options)
  - use blocks for complex attribute or index specifications

Changes:

  - changed the implementation of Resultset.size to get more accurate estimations
  - changed the indexing of active_record or datamapper models when declared as attributes or indexes
    in a blueprint (indexes now all attributes of the object instead of using to_s)

##0.3.3 (December 13th, 2010)

Features:

  - Support for multi language stop words. The implementation was inspired by John Leachs xapian-fu gem
  - Support for query spelling correction (similar to Google's 'did you mean...'). This feature is only
    available for persistent databases (due to a limitation of Xapian)

Changes:

  - Languages must be configured by the iso language code (:en, :de, ...). No more support for the english
    language names (:english, :german, ...)
  - Reduced the memory footprint when reindexing large tables

##0.3.2 (December 10th, 2010)

Features:

  - Moved the per_page option from Resultset.paginate to Database.search
  - Added support for language settings (global and dynamic per object)
  - Added support for xapian stemmers
  - Removed the dependency to progressbar (but it is still used if available)
  - Made the rebuild_xapian_index method silent by default (use :verbose => true to get status info)

##0.3.1 (December 6th, 2010)

Bugfixes:

  - Fixed the gemspec

##0.3.0 (December 4th, 2010)

Features:

  - Rails integration with configuration file (config/xapian_db.yml) and automatic setup

##0.2.0 (December 1st, 2010)

Features:

  - Blueprint configuration extended
  - Adapter for Datamapper
  - Search by attribute names
  - Search with wildcards
  - Document attributes can carry anything that is serializable by YAML

##0.1.0 (November 23th, 2010)

Proof of concept, not really useful for real world usage
