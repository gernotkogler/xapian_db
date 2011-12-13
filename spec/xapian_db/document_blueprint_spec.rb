# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe XapianDb::DocumentBlueprint do

  describe ".configured_classes" do

    it "returns all configured classes" do
      XapianDb::DocumentBlueprint.instance_variable_set(:@blueprints, nil)
      XapianDb::DocumentBlueprint.configured_classes.size.should == 0

      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.index :id
        blueprint.index :name
      end
      XapianDb::DocumentBlueprint.configured_classes.should == [IndexedObject]
    end
  end

  describe ".configured?(name)" do

    before :each do
      XapianDb::DocumentBlueprint.instance_variable_set(:@blueprints, nil)
    end

    it "returns true, if a blueprint with the given name is configured" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.index :id
        blueprint.index :name
      end
      XapianDb::DocumentBlueprint.configured?(:IndexedObject).should be_true
    end

    it "returns false, if no blueprints are configured" do
      XapianDb::DocumentBlueprint.configured?(:IndexedObject).should be_false
    end

    it "returns false, if a blueprint with the given name is not configured" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.index :id
        blueprint.index :name
      end
      XapianDb::DocumentBlueprint.configured?(:NotConfigured).should be_false
    end

  end

  describe ".blueprint_for(name)" do

    before :each do
      XapianDb::DocumentBlueprint.instance_variable_set(:@blueprints, nil)
    end

    it "returns the blueprint for a class" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.index :id
        blueprint.index :name
      end
      XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject).should be_a_kind_of XapianDb::DocumentBlueprint
    end

    it "returns the blueprint for the super class if no specific blueprint is configured" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.index :id
        blueprint.index :name
      end
      class InheritedIndexedObject < IndexedObject; end
      XapianDb::DocumentBlueprint.blueprint_for(:InheritedIndexedObject).should == XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject)
    end

    it "can handle namespaces" do
      XapianDb::DocumentBlueprint.setup("Namespace::IndexedObject") do |blueprint|
        blueprint.index :id
        blueprint.index :name
      end
      XapianDb::DocumentBlueprint.blueprint_for("Namespace::IndexedObject").should be_a_kind_of XapianDb::DocumentBlueprint
    end

    it "returns nil if there is no blueprint configuration for a class" do
      XapianDb::DocumentBlueprint.blueprint_for(:Object).should_not be
    end

    it "returns nil if there is no blueprint configuration at all" do
      XapianDb::DocumentBlueprint.blueprint_for(:Object).should_not be
    end

    it "accepts a string for the class name" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.index :id
        blueprint.index :name
      end
      XapianDb::DocumentBlueprint.blueprint_for("IndexedObject").should be_a_kind_of XapianDb::DocumentBlueprint
    end

    it "accepts a symbol for the class name" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.index :id
        blueprint.index :name
      end
      XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject).should be_a_kind_of XapianDb::DocumentBlueprint
    end

  end

  describe ".searchable_prefixes" do

    it "should return an array of all method names configured to be indexed" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.index :id
        blueprint.index :name
      end
      XapianDb::DocumentBlueprint.searchable_prefixes.should include(:id, :name)
    end

    it "should return %w(indexed_class) if no attributes and no indexes are configured" do
      XapianDb::DocumentBlueprint.instance_variable_set(:@blueprints, nil)
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
      end
      XapianDb::DocumentBlueprint.searchable_prefixes.should == %w(indexed_class)
    end
  end

  describe ".attributes" do

    it "should return an array of all defined attributes" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attribute :id
        blueprint.attribute :name
      end
      XapianDb::DocumentBlueprint.attributes.should include(:id, :name)
    end

    it "should return an empty array if no attributes are configured" do
      XapianDb::DocumentBlueprint.instance_variable_set(:@blueprints, nil)
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.index :id
        blueprint.index :name
      end
      XapianDb::DocumentBlueprint.attributes.should == []
    end
  end

  describe ".type_info_for(attribute)" do

    before :each do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attribute :date, :as => :date
        blueprint.attribute :untyped
      end
    end

    it "should return the type of an attribute if one is defined" do
      XapianDb::DocumentBlueprint.type_info_for(:date).should == :date
    end

    it "should return :generic if no type is defined" do
      XapianDb::DocumentBlueprint.type_info_for(:untyped).should == :generic
    end

    it "returns nil if the attribute is not defined" do
      XapianDb::DocumentBlueprint.type_info_for(:not_defined).should_not be
    end

    it "returns nil if no blueprints are defined defined" do
      XapianDb::DocumentBlueprint.instance_variable_set(:@blueprints, nil)
      XapianDb::DocumentBlueprint.type_info_for(:not_defined).should_not be
    end

  end

  describe ".setup (class)" do
    it "stores a blueprint for a given class" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject)
      XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject).should be_a_kind_of(XapianDb::DocumentBlueprint)
    end

    it "does replace the blueprint for a class if the class is reloaded" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject)
      XapianDb::DocumentBlueprint.configured_classes.size.should == 1
      # reload IndexedObject
      Object.send(:remove_const, :IndexedObject)
      load File.expand_path('../../basic_mocks.rb', __FILE__)
      XapianDb::DocumentBlueprint.setup(:IndexedObject)
      XapianDb::DocumentBlueprint.configured_classes.size.should == 1
    end

    it "raises an exception if a method with the same name has different type declarations" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attribute :date, :as => :date
      end
      lambda { XapianDb::DocumentBlueprint.setup(:OtherIndexedObject) do |blueprint|
        blueprint.attribute :date, :as => :number
      end }.should raise_error ArgumentError
    end

    it "allows blueprint definitions with symbols" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject)
      XapianDb::DocumentBlueprint.blueprint_for('IndexedObject').should_not be_nil
    end

    it "allows blueprint definitions with strings" do
      XapianDb::DocumentBlueprint.setup('IndexedObject')
      XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject).should_not be_nil
    end

    it "lazy-loads blueprint classes" do
      lambda do
        XapianDb::DocumentBlueprint.setup(:NotYetLoadedClass)
        class NotYetLoadedClass; end
      end.should_not raise_error
      XapianDb::DocumentBlueprint.blueprint_for(:NotYetLoadedClass).should_not be_nil
    end

  end

  describe ".value_number_for(:attribute)" do

    before :each do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attribute :id
        blueprint.attribute :name
      end
      @position_offset = 2 # slots 0 and 1 are reserved
    end

    it "returns the value number of an indexed method" do
      XapianDb::DocumentBlueprint.value_number_for(:name).should == @position_offset + 1
    end

    it "accepts a string as an argument" do
      XapianDb::DocumentBlueprint.value_number_for("name").should == @position_offset + 1
    end

    it "raises an argument error if the method is not indexed" do
      lambda { XapianDb::DocumentBlueprint.value_number_for(:not_indexed) }.should raise_error ArgumentError
    end

    it "raises an argument error if no blueprints are defined" do
      XapianDb::DocumentBlueprint.instance_variable_set(:@blueprints, nil)
      XapianDb::DocumentBlueprint.instance_variable_set(:@attributes, nil)
      lambda { XapianDb::DocumentBlueprint.value_number_for(:not_indexed) }.should raise_error ArgumentError
    end

    it "handles multiple blueprints whith the same indexed method at different positions" do
      XapianDb::DocumentBlueprint.setup(:OtherIndexedObject) do |blueprint|
        blueprint.index :id
        blueprint.index :not_in_alphabetical_order
        blueprint.index :name
      end
      XapianDb::DocumentBlueprint.value_number_for(:name).should == @position_offset + 1
    end

    it "returns 0 for :indexed_class" do
      XapianDb::DocumentBlueprint.value_number_for(:indexed_class).should == 0
    end

    it "calculates the value number in alphabetical order even if the attributes are not declared in alphabetical order" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attribute :date_of_birth, :as => :date
        blueprint.attribute :empty_field
        blueprint.attribute :id
        blueprint.attribute :name
        blueprint.attribute :array
      end
      XapianDb::DocumentBlueprint.value_number_for(:array).should == @position_offset
    end

  end

  describe "#adapter (symbol)" do
    it "overides the adapter for the configured class" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.adapter :generic
      end
      XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject)._adapter.should be_equal XapianDb::Adapters::GenericAdapter
    end
  end

  describe "#_adapter" do

    it "returns the generic adapter if no configration is present" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attribute :name
      end
      XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject)._adapter.should be_equal XapianDb::Adapters::GenericAdapter
    end

    it "returns the globally configured adapter if specified" do
      XapianDb::Config.stub(:adapter).and_return(XapianDb::Adapters::ActiveRecordAdapter)
      XapianDb::DocumentBlueprint.setup(:ActiveRecordObject) do |blueprint|
        blueprint.attribute :name
      end
      XapianDb::DocumentBlueprint.blueprint_for(:ActiveRecordObject)._adapter.should be_equal XapianDb::Adapters::ActiveRecordAdapter
    end

    it "returns the adapter configured for this blueprint if specified" do
      XapianDb::DocumentBlueprint.setup(:DatamapperObject) do |blueprint|
        blueprint.adapter :datamapper
        blueprint.attribute :name
      end
      XapianDb::DocumentBlueprint.blueprint_for(:DatamapperObject)._adapter.should be_equal XapianDb::Adapters::DatamapperAdapter
    end

  end

  describe "#attribute" do

    before :each do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attribute :id
      end
    end

    it "adds an attribute to the blueprint" do
      XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject).attribute_names.should include(:id)
    end

    it "adds the attribute to the indexed methods by default" do
      XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject).indexed_method_names.should include(:id)
    end

    it "does not index the attribute if the :index option ist set to false " do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attribute :id, :index => false
      end
      XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject).indexed_method_names.should_not include(:id)
    end

    it "allows to specify a weight for the attribute" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attribute :id, :weight=> 10
      end
      XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject).options_for_indexed_method(:id).weight.should == 10
    end

    it "accepts a block to specify complex attribute evaluation" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attribute :complex do
          if @id == 1
            "One"
          else
            "Not one"
          end
        end
      end
      XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject).attribute_names.should include(:complex)
    end

    it "throws an exception if the attribute name maps to a Xapian::Document method name" do
      XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject).attribute_names.should include(:id)
      lambda{XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attribute :data
      end}.should raise_error ArgumentError

    end

  end

  describe "#attributes" do

    it "allows to declare one single attribute" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attributes :id
      end
      XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject).attribute_names.should include(:id)
    end

    it "allows to declare multiple attributes in a single statement (but without options)" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attributes :id, :name, :first_name
      end
      XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject).attribute_names.should include(:id, :name, :first_name)
    end

    it "throws an exception if the attribute name maps to a Xapian::Document method name" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attributes :id, :name, :first_name
      end
      XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject).attribute_names.should include(:id)
      lambda{XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attributes :data
      end}.should raise_error ArgumentError
    end
  end

  describe "#index" do

    before :each do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.index :id
      end
    end

    it "adds an indexed value to the blueprint" do
      XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject).options_for_indexed_method(:id).should be_a_kind_of XapianDb::DocumentBlueprint::IndexOptions
    end

    it "defaults the weight option to 1" do
      XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject).options_for_indexed_method(:id).weight.should == 1
    end

    it "accepts weight as an option" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.index :id, :weight => 10
      end
      XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject).options_for_indexed_method(:id).weight.should == 10
    end

    it "does not accept a type option" do
      lambda { XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.index :date, :as => :date
      end }.should raise_error ArgumentError
    end

    it "allows to declare two methods (can distinguish this from a method with an options hash)" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.index :id, :name
      end
      XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject).indexed_method_names.should include(:id, :name)
    end

    it "allows to declare multiple methods (but without options)" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.index :id, :name, :first_name
      end
      XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject).indexed_method_names.should include(:id, :name, :first_name)
    end

  end

  describe "#ignore_if" do

    it "accepts a block and stores the block as a Proc" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.index :id
        blueprint.ignore_if {
          active == false
        }
      end
      XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject).instance_variable_get(:@ignore_expression).should be_a_kind_of Proc
    end
  end

  describe "#should_index? obj" do

    it "should return true if no ignore expression is given" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attribute :id
      end
      blueprint = XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject)
      obj = IndexedObject.new 1
      blueprint.should_index?(obj).should be_true
    end

    it "should return false if the ignore expression evaluates to true" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attribute :id
        blueprint.ignore_if {id == 1}
      end
      blueprint = XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject)
      obj = IndexedObject.new 1
      blueprint.should_index?(obj).should be_false
    end

    it "should return true if the ignore expression evaluates to false" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attribute :id
        blueprint.ignore_if {id == 2}
      end
      blueprint = XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject)
      obj = IndexedObject.new 1
      blueprint.should_index?(obj).should be_true
    end

  end

  describe "base_query" do

    it "accepts a base query expression" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attribute :array
        blueprint.base_query ActiveRecordObject.includes(:children)
      end
      XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject).lazy_base_query.should be
    end

    it "converts an explicit base query expression to a proc" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attribute :array
        blueprint.base_query ActiveRecordObject.includes(:children)
      end
      XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject).lazy_base_query.should be_a Proc
    end

    it "accepts a base query expression inside a block" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attribute :array
        blueprint.base_query { ActiveRecordObject.includes(:children) }
      end
      XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject).lazy_base_query.should be_a Proc
    end
  end


  describe "#natural_sort_order" do

    it "defaults to id if not specified" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
      end
      XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject)._natural_sort_order.should == :id
    end

    it "accepts a method symbol" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.natural_sort_order :name
      end
      XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject)._natural_sort_order.should == :name
    end

    it "accepts a block" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.natural_sort_order do
          @id
        end
      end
      XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject)._natural_sort_order.should be_a Proc
    end

    it "raises an ArgumentError, if a method name AND a block are given" do
      lambda { XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.natural_sort_order :name do
          @id
        end
      end }.should raise_error ArgumentError
    end

  end


  describe "#accessors_module" do

    before :each do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attribute :array
        blueprint.attribute :date_of_birth, :as => :date
        blueprint.attribute :empty_field
        blueprint.attribute :id
        blueprint.attribute :name
      end
      @blueprint = XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject)

      @doc = Xapian::Document.new
      @doc.add_value(0, "IndexedObject")
      @doc.add_value(XapianDb::DocumentBlueprint.value_number_for(:array), [1, "two", Date.new(2011, 1, 1)].to_yaml)
      @doc.add_value(XapianDb::DocumentBlueprint.value_number_for(:date_of_birth), "20110101")
      @doc.add_value(XapianDb::DocumentBlueprint.value_number_for(:empty_field), nil.to_yaml)
      @doc.add_value(XapianDb::DocumentBlueprint.value_number_for(:id), 1.to_yaml)
      @doc.add_value(XapianDb::DocumentBlueprint.value_number_for(:name), "Kogler".to_yaml)
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

    it "adds accessor methods that deserialize values to native objects" do
      @doc.date_of_birth.should == Date.new(2011, 1, 1)
      @doc.array.should == [1, "two", Date.new(2011, 1, 1)]
    end
  end

  describe "#type_map" do

    let(:blueprint) { XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject) }

    before :each do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attribute :date, :as => :date
        blueprint.attribute :untyped
      end
    end

    it "should return a hash table" do
      blueprint.type_map.should be_a Hash
    end

    it "contains the type of an indexed method if a type is defined" do
      blueprint.type_map[:date].should == :date
    end

    it "contains :generic for an indexed method if no type is defined" do
      blueprint.type_map[:untyped].should == :generic
    end

  end

end
