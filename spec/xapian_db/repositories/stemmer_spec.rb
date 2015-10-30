# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe XapianDb::Repositories::Stemmer do

  describe ".stemmer_for(iso_cd)" do
    it "returns nil for iso code nil" do
      expect(XapianDb::Repositories::Stemmer.stemmer_for(nil)).not_to be
    end

    it "returns a Xapian::Stem object for a supported language iso code" do
      expect(XapianDb::Repositories::Stemmer.stemmer_for(:de)).to be_a_kind_of Xapian::Stem
    end

    it "caches already used stemmers" do
      stemmer = XapianDb::Repositories::Stemmer.stemmer_for(:de)
      expect(XapianDb::Repositories::Stemmer.stemmer_for(:de)).to be_equal stemmer
    end

    it "accepts :none for a stemmer without a language" do
      expect(XapianDb::Repositories::Stemmer.stemmer_for(:none)).to be_a_kind_of Xapian::Stem
    end

    it "raises an argument error if the language is not supported" do
      expect {XapianDb::Repositories::Stemmer.stemmer_for(:not_supported)}.to raise_error ArgumentError
    end

  end

end
