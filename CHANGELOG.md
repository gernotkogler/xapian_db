##0.3.4 (December 14th, 2010)

Features:

  - Perform searches on indexed classes to restrict the results to objects of a specific class

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
