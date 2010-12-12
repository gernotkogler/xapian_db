# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe XapianDb::Repositories::Stopper do

  describe ".stopper_for(iso_cd)" do
    it "returns nil for iso code nil" do
      XapianDb::Repositories::Stopper.stopper_for(nil).should_not be
    end

    it "returns a Xapian::SimpleStopper object for a supported language iso code" do
      XapianDb::Repositories::Stopper.stopper_for(:de).should be_a_kind_of Xapian::SimpleStopper
    end

    it "caches already used stoppers" do
      stopper = XapianDb::Repositories::Stopper.stopper_for(:de)
      XapianDb::Repositories::Stopper.stopper_for(:de).should be_equal stopper
    end

    it "raises an argument error if the language is not supported" do
      lambda {XapianDb::Repositories::Stopper.stopper_for(:not_supported)}.should raise_error ArgumentError
    end

    it "creates a stopper thata contains the stop words for its language" do
      stopper = XapianDb::Repositories::Stopper.stopper_for(:de)
      stopper.call("und").should be_true
    end

  end

end
