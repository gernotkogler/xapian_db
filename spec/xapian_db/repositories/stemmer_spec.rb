# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe XapianDb::Repositories::Stemmer do

  describe ".stemmer_for(iso_cd)" do
    it "returns nil for iso code nil" do
      XapianDb::Repositories::Stemmer.stemmer_for(nil).should_not be
    end
  end

  describe ".stemmer_for(iso_cd)" do
    it "returns a Xapian::Stem object for a supported language iso code" do
      XapianDb::Repositories::Stemmer.stemmer_for(:de).should be_a_kind_of Xapian::Stem
    end
  end

  describe ".stemmer_for(iso_cd)" do
    it "caches already used stemmers" do
      stemmer = XapianDb::Repositories::Stemmer.stemmer_for(:de)
      XapianDb::Repositories::Stemmer.stemmer_for(:de).should be_equal stemmer
    end
  end

  describe ".stemmer_for(iso_cd)" do
    it "accepts :none for a stemer without a language" do
      XapianDb::Repositories::Stemmer.stemmer_for(:none).should be_a_kind_of Xapian::Stem
    end
  end

  describe ".stemmer_for(iso_cd)" do
    it "raises an argument error if the language is not supported" do
      lambda {XapianDb::Repositories::Stemmer.stemmer_for(:not_supported)}.should raise_error ArgumentError
    end
  end

end
