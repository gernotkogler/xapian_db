# encoding: utf-8

module XapianDb
  module Repositories

    # The stemmer is a repository that manages stemmers for the supported
    # languges
    # @author Gernot Kogler
    class Stemmer

      class << self

        # Get or build the stemmer for a language
        # @param [String] iso_cd The iso code for the language (:en, :de ...)
        # @return [Xapian::Stem] The Stemmer for this lanugage
        def stemmer_for(iso_cd)
          @stemmers ||= {}
          return nil if iso_cd.nil?
          key = iso_cd.to_sym

          # Do we already have a stemmer for this language?
          return @stemmers[key] unless @stemmers[key].nil?

          # Do we support this language?
          unless (LANGUAGE_MAP.keys + [:none]).include?(key)
            raise ArgumentError.new "Language #{iso_cd} is not supported by XapianDb (remember to use the language iso codes)"
          end

          # Let's build the stemmer
          @stemmers[key] = Xapian::Stem.new(key.to_s)
        end

      end

    end

  end
end