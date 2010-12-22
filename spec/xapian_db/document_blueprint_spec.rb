# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe XapianDb::DocumentBlueprint do

  describe ".searchable_prefixes" do

    it "should return an array of all method names configured to be indexed" do
      XapianDb::DocumentBlueprint.setup(IndexedObject) do |blueprint|
        blueprint.index :id
        blueprint.index :name
      end
      XapianDb::DocumentBlueprint.searchable_prefixes.should include(:id, :name)
    end

    it "should return an array with unique values" do
      XapianDb::DocumentBlueprint.setup(IndexedObject) do |blueprint|
        blueprint.index :id
        blueprint.index :name
      end
      XapianDb::DocumentBlueprint.setup(Object) do |blueprint|
        blueprint.index :id
        blueprint.index :name
      end
      XapianDb::DocumentBlueprint.searchable_prefixes.select{|prefix| prefix == :id}.size.should ==1
      XapianDb::DocumentBlueprint.searchable_prefixes.select{|prefix| prefix == :name}.size.should ==1
    end

    it "should return an empty array if no blueprints are configured" do
      # We have to reload the DocumentBlueprint to get rid aof any configurations
      XapianDb.send(:remove_const, 'DocumentBlueprint')
      load File.expand_path(File.dirname(__FILE__) + '/../../lib/xapian_db/document_blueprint.rb')
      XapianDb::DocumentBlueprint.searchable_prefixes.should == []
    end

  end

  describe ".setup (singleton)" do
    it "stores a blueprint for a given class" do
      XapianDb::DocumentBlueprint.setup(IndexedObject)
      XapianDb::DocumentBlueprint.blueprint_for(IndexedObject).should be_a_kind_of(XapianDb::DocumentBlueprint)
    end

  end

  describe ".adapter=" do
    it "sets the adpater for the configured class" do
      XapianDb::DocumentBlueprint.setup(IndexedObject) do |blueprint|
        blueprint.adapter = DemoAdapter
      end
      XapianDb::DocumentBlueprint.blueprint_for(IndexedObject).adapter.should == DemoAdapter
    end
  end

  describe ".attribute" do

    before :each do
      XapianDb::DocumentBlueprint.setup(IndexedObject) do |blueprint|
        blueprint.attribute :id
      end
    end

    it "adds an attribute to the blueprint" do
      XapianDb::DocumentBlueprint.blueprint_for(IndexedObject).attribute_names.should include(:id)
    end

    it "adds the attribute to the indexed methods by default" do
      XapianDb::DocumentBlueprint.blueprint_for(IndexedObject).indexed_method_names.should include(:id)
    end

    it "does not index the attribute if the :index option ist set to false " do
      XapianDb::DocumentBlueprint.setup(IndexedObject) do |blueprint|
        blueprint.attribute :id, :index => false
      end
      XapianDb::DocumentBlueprint.blueprint_for(IndexedObject).indexed_method_names.should_not include(:id)
    end

    it "allows to specify a weight for the attribute" do
      XapianDb::DocumentBlueprint.setup(IndexedObject) do |blueprint|
        blueprint.attribute :id, :weight=> 10
      end
      XapianDb::DocumentBlueprint.blueprint_for(IndexedObject).options_for_indexed_method(:id).weight.should == 10
    end

    it "accepts a block to specify complex attribute evaluation" do
      XapianDb::DocumentBlueprint.setup(IndexedObject) do |blueprint|
        blueprint.attribute :complex do
          if @id == 1
            "One"
          else
            "Not one"
          end
        end
      end
      XapianDb::DocumentBlueprint.blueprint_for(IndexedObject).attribute_names.should include(:complex)
    end

    it "throws an exception if the attribute name maps to a Xapian::Document method name" do
      XapianDb::DocumentBlueprint.blueprint_for(IndexedObject).attribute_names.should include(:id)
      lambda{XapianDb::DocumentBlueprint.setup(IndexedObject) do |blueprint|
        blueprint.attribute :data
      end}.should raise_error ArgumentError

    end

  end

  describe ".attributes" do

    it "allows to declare one single attribute" do
      XapianDb::DocumentBlueprint.setup(IndexedObject) do |blueprint|
        blueprint.attributes :id
      end
      XapianDb::DocumentBlueprint.blueprint_for(IndexedObject).attribute_names.should include(:id)
    end

    it "allows to declare multiple attributes in a single statement (but without options)" do
      XapianDb::DocumentBlueprint.setup(IndexedObject) do |blueprint|
        blueprint.attributes :id, :name, :first_name
      end
      XapianDb::DocumentBlueprint.blueprint_for(IndexedObject).attribute_names.should include(:id, :name, :first_name)
    end

    it "throws an exception if the attribute name maps to a Xapian::Document method name" do
      XapianDb::DocumentBlueprint.blueprint_for(IndexedObject).attribute_names.should include(:id)
      lambda{XapianDb::DocumentBlueprint.setup(IndexedObject) do |blueprint|
        blueprint.attributes :data
      end}.should raise_error ArgumentError
    end
  end

  describe ".index" do

    before :all do
      XapianDb::DocumentBlueprint.setup(IndexedObject) do |blueprint|
        blueprint.index :id
      end
    end

    it "adds an indexed value to the blueprint" do
      XapianDb::DocumentBlueprint.blueprint_for(IndexedObject).options_for_indexed_method(:id).should be_a_kind_of XapianDb::DocumentBlueprint::IndexOptions
    end

    it "defaults the weight option to 1" do
      XapianDb::DocumentBlueprint.blueprint_for(IndexedObject).options_for_indexed_method(:id).weight.should == 1
    end

    it "accepts weight as an option" do
      XapianDb::DocumentBlueprint.setup(IndexedObject) do |blueprint|
        blueprint.index :id, :weight => 10
      end
      XapianDb::DocumentBlueprint.blueprint_for(IndexedObject).options_for_indexed_method(:id).weight.should == 10
    end

    it "allows to declare two methods (can distinguish this from a method with an options hash)" do
      XapianDb::DocumentBlueprint.setup(IndexedObject) do |blueprint|
        blueprint.index :id, :name
      end
      XapianDb::DocumentBlueprint.blueprint_for(IndexedObject).indexed_method_names.should include(:id, :name)
    end

    it "allows to declare multiple methods (but without options)" do
      XapianDb::DocumentBlueprint.setup(IndexedObject) do |blueprint|
        blueprint.index :id, :name, :first_name
      end
      XapianDb::DocumentBlueprint.blueprint_for(IndexedObject).indexed_method_names.should include(:id, :name, :first_name)
    end

  end

  describe ".accessors_module" do

    before :each do
      XapianDb::DocumentBlueprint.setup(IndexedObject) do |blueprint|
        blueprint.attribute :array
        blueprint.attribute :date_of_birth
        blueprint.attribute :empty_field
        blueprint.attribute :id
        blueprint.attribute :name
      end
      @blueprint = XapianDb::DocumentBlueprint.blueprint_for(IndexedObject)

      @doc = Xapian::Document.new
      @doc.add_value(0, "IndexedObject")
      @doc.add_value(1, [1, "two", Date.today].to_yaml)
      @doc.add_value(2, Date.today.to_yaml)
      @doc.add_value(3, nil.to_yaml)
      @doc.add_value(4, 1.to_yaml)
      @doc.add_value(5, "Kogler".to_yaml)
      @doc.extend @blueprint.accessors_module
    end

    it "builds an accessor module for the blueprint" do
      @blueprint.accessors_module.should be_a_kind_of Module
    end

    it "adds accessor methods for each configured field" do
      @blueprint.accessors_module.instance_methods.should include(:id, :name, :date_of_birth)
    end

    it "adds accessor methods that can handle nil" do
      @doc.empty_field.should be_nil
    end

    it "adds an accessor method for the class of the indexed object" do
      @doc.indexed_class.should == "IndexedObject"
    end

    it "adds accessor methods that deserialize values using YAML" do
      @doc.date_of_birth.should == Date.today
      @doc.array.should == [1, "two", Date.today]
    end

  end

  describe ".value_index_for(attribute)" do

    before :each do
      XapianDb::DocumentBlueprint.setup(IndexedObject) do |blueprint|
        blueprint.attribute :name
        blueprint.attribute :first_name
      end
      @blueprint = XapianDb::DocumentBlueprint.blueprint_for(IndexedObject)
    end

    it "raises an argument error if the attribute name is unknown" do
      lambda{@blueprint.value_index_for(:unknown)}.should raise_error ArgumentError
    end

    it "returns the value index of an attribute (to access the value from a Xapian:Document)" do
      @blueprint.value_index_for(:name).should == 2
    end

  end

end