# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe XapianDb::DocumentBlueprint do

  describe ".configured_classes" do

    it "returns all configured classes" do
      XapianDb::DocumentBlueprint.instance_variable_set(:@blueprints, nil)
      XapianDb::DocumentBlueprint.configured_classes.size.should == 0

      XapianDb::DocumentBlueprint.setup(IndexedObject) do |blueprint|
        blueprint.index :id
        blueprint.index :name
      end
      XapianDb::DocumentBlueprint.configured_classes.size.should == 1
      XapianDb::DocumentBlueprint.configured_classes.first.should == IndexedObject
    end

  end

  describe ".blueprint_for(klass)" do

    it "returns the blueprint for a class" do
      XapianDb::DocumentBlueprint.instance_variable_set(:@blueprints, nil)
      XapianDb::DocumentBlueprint.setup(IndexedObject) do |blueprint|
        blueprint.index :id
        blueprint.index :name
      end
      XapianDb::DocumentBlueprint.blueprint_for(IndexedObject).should be_a_kind_of XapianDb::DocumentBlueprint
    end

    it "returns the blueprint for the super class if no specific blueprint is configured" do
      XapianDb::DocumentBlueprint.instance_variable_set(:@blueprints, nil)
      XapianDb::DocumentBlueprint.setup(IndexedObject) do |blueprint|
        blueprint.index :id
        blueprint.index :name
      end
      class InheritedIndexedObject < IndexedObject; end
      XapianDb::DocumentBlueprint.blueprint_for(InheritedIndexedObject).should == XapianDb::DocumentBlueprint.blueprint_for(IndexedObject)
    end

    it "can handle namespaces" do
      XapianDb::DocumentBlueprint.instance_variable_set(:@blueprints, nil)
      XapianDb::DocumentBlueprint.setup(Namespace::IndexedObject) do |blueprint|
        blueprint.index :id
        blueprint.index :name
      end
      XapianDb::DocumentBlueprint.blueprint_for(Namespace::IndexedObject).should be_a_kind_of XapianDb::DocumentBlueprint
    end

    it "raises an exception if there is no blueprint configuration for a class" do
      lambda {XapianDb::DocumentBlueprint.blueprint_for(Object)}.should raise_error
    end

    it "raises an exception if there is no blueprint configuration at all" do
      XapianDb::DocumentBlueprint.instance_variable_set(:@blueprints, nil)
      lambda {XapianDb::DocumentBlueprint.blueprint_for(Object)}.should raise_error
    end

  end

  describe ".searchable_prefixes" do

    it "should return an array of all method names configured to be indexed" do
      XapianDb::DocumentBlueprint.setup(IndexedObject) do |blueprint|
        blueprint.index :id
        blueprint.index :name
      end
      XapianDb::DocumentBlueprint.searchable_prefixes.should include(:id, :name)
    end

    it "should return a hash with unique values" do
      XapianDb::DocumentBlueprint.setup(IndexedObject) do |blueprint|
        blueprint.index :id
        blueprint.index :name
      end
      XapianDb::DocumentBlueprint.setup(Object) do |blueprint|
        blueprint.index :id
        blueprint.index :name
      end
      XapianDb::DocumentBlueprint.searchable_prefixes.select{|prefix, options| prefix == :id}.size.should ==1
      XapianDb::DocumentBlueprint.searchable_prefixes.select{|prefix, options| prefix == :name}.size.should ==1
    end

    it "should set a range filter on a method specified as date at the right position based on sorted method names" do
      XapianDb::DocumentBlueprint.setup(Object) do |blueprint|
        blueprint.index :id
        blueprint.index :name
        blueprint.index :date, :as => :date
        blueprint.attribute :new_date, :as => :date
      end
      XapianDb::DocumentBlueprint.searchable_prefixes.select{|prefix, options| prefix == :date && options.as == :date && options.position == 1 }.size.should == 1
      XapianDb::DocumentBlueprint.searchable_prefixes.select{|prefix, options| prefix == :new_date && options.as == :date && options.position == 4 }.size.should == 1
    end

    it "should return an empty hash if no blueprints are configured" do
      XapianDb::DocumentBlueprint.instance_variable_set(:@blueprints, nil)
      XapianDb::DocumentBlueprint.searchable_prefixes.should == {}
    end

  end

  describe ".setup (class)" do
    it "stores a blueprint for a given class" do
      XapianDb::DocumentBlueprint.setup(IndexedObject)
      XapianDb::DocumentBlueprint.blueprint_for(IndexedObject).should be_a_kind_of(XapianDb::DocumentBlueprint)
    end

    it "does replace the blueprint for a class if the class is reloaded" do
      XapianDb::DocumentBlueprint.setup(IndexedObject)
      XapianDb::DocumentBlueprint.configured_classes.size.should == 1
      # reload IndexedObject
      Object.send(:remove_const, :IndexedObject)
      load File.expand_path('../../basic_mocks.rb', __FILE__)
      XapianDb::DocumentBlueprint.setup(IndexedObject)
      XapianDb::DocumentBlueprint.configured_classes.size.should == 1
    end
  end

  describe ".value_number_for(:indexed_method)" do

    before :each do
      XapianDb::DocumentBlueprint.setup(IndexedObject) do |blueprint|
        blueprint.index :id
        blueprint.index :name
      end
    end

    it "returns the value number of an indexed method" do
      XapianDb::DocumentBlueprint.value_number_for(:name).should == 2
    end

    it "accepts a string as an argument" do
      XapianDb::DocumentBlueprint.value_number_for("name").should == 2
    end

    it "raises an argument error if the method is not indexed" do
      lambda { XapianDb::DocumentBlueprint.value_number_for(:not_indexed) }.should raise_error ArgumentError
    end

    it "handles multiple blueprints whith the same indexed method at different positions" do
      class OtherIndexedObject
      end
      XapianDb::DocumentBlueprint.setup(OtherIndexedObject) do |blueprint|
        blueprint.index :id
        blueprint.index :not_in_alphabetical_order
        blueprint.index :name
      end
      XapianDb::DocumentBlueprint.value_number_for(:name).should == 2
    end

  end

  describe "#adapter (symbol)" do
    it "overides the adapter for the configured class" do
      XapianDb::DocumentBlueprint.setup(IndexedObject) do |blueprint|
        blueprint.adapter :generic
      end
      XapianDb::DocumentBlueprint.blueprint_for(IndexedObject)._adapter.should be_equal XapianDb::Adapters::GenericAdapter
    end
  end

  describe "#attribute" do

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

  describe "#attributes" do

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

  describe "#index" do

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

  describe "#ignore_if" do

    it "accepts a block and stores the block as a Proc" do
      XapianDb::DocumentBlueprint.setup(IndexedObject) do |blueprint|
        blueprint.index :id
        blueprint.ignore_if {
          active == false
        }
      end
      XapianDb::DocumentBlueprint.blueprint_for(IndexedObject).instance_variable_get(:@ignore_expression).should be_a_kind_of Proc
    end
  end

  describe "#should_index? obj" do

    it "should return true if no ignore expression is given" do
      XapianDb::DocumentBlueprint.setup(IndexedObject) do |blueprint|
        blueprint.attribute :id
      end
      blueprint = XapianDb::DocumentBlueprint.blueprint_for(IndexedObject)
      obj = IndexedObject.new 1
      blueprint.should_index?(obj).should be_true
    end

    it "should return false if the ignore expression evaluates to true" do
      XapianDb::DocumentBlueprint.setup(IndexedObject) do |blueprint|
        blueprint.attribute :id
        blueprint.ignore_if {id == 1}
      end
      blueprint = XapianDb::DocumentBlueprint.blueprint_for(IndexedObject)
      obj = IndexedObject.new 1
      blueprint.should_index?(obj).should be_false
    end

    it "should return true if the ignore expression evaluates to false" do
      XapianDb::DocumentBlueprint.setup(IndexedObject) do |blueprint|
        blueprint.attribute :id
        blueprint.ignore_if {id == 2}
      end
      blueprint = XapianDb::DocumentBlueprint.blueprint_for(IndexedObject)
      obj = IndexedObject.new 1
      blueprint.should_index?(obj).should be_true
    end

  end

  describe "#accessors_module" do

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

end
