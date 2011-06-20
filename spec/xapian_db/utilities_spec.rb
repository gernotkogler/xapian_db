# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

include XapianDb::Utilities

describe XapianDb::Utilities do

  describe ".constantize(camel_cased_word)" do

    it "can resolve Namespaces" do
      constantize("Namespace::IndexedObject").should be_equal Namespace::IndexedObject
    end

  end

end