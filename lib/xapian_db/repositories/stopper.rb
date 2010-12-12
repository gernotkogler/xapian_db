# encoding: utf-8

module XapianDb
  module Repositories

    # The stopper is a repository that manages stoppers for the supported
    # languges
    # @author Gernot Kogler
    class Stopper

      class << self

        # Get or build the stopper for a language
        # @param [Symbol, String] iso_cd The iso code for the language (:en, :de ...)
        # @return [Xapian::SimpleStopper] The Stopper for this lanugage
        def stopper_for(iso_cd)
          @stoppers ||= {}
          return nil if iso_cd.nil?
          key = iso_cd.to_sym

          # Do we already have a stopper for this language?
          return @stoppers[key] unless @stoppers[key].nil?

          # Do we support this language?
          unless (LANGUAGE_MAP.keys + [:none]).include?(key)
            raise ArgumentError.new "Language #{iso_cd} is not supported by XapianDb (remember to use the language iso codes)"
          end

          # build the stopper
          stopper = Xapian::SimpleStopper.new
          stopwords_file = File.join(File.dirname(__FILE__), '../stopwords', "#{iso_cd}.txt")
          open(stopwords_file, "r") do |file|
            file.each do |word|
              stopper.add word.chomp
            end
          end
          @stoppers[key] = stopper
        end

      end

    end

  end
end