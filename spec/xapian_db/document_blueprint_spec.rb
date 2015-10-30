# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe XapianDb::DocumentBlueprint do

  describe ".reset" do

    it "clears the blueprint configuration" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.index :id
        blueprint.index :name
      end
      XapianDb::DocumentBlueprint.reset

      expect(XapianDb::DocumentBlueprint.configured_classes).to eq([])
    end
  end

  describe ".configured_classes" do

    it "returns all configured classes" do
      XapianDb::DocumentBlueprint.reset
      expect(XapianDb::DocumentBlueprint.configured_classes.size).to eq(0)

      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.index :id
        blueprint.index :name
      end
      expect(XapianDb::DocumentBlueprint.configured_classes).to eq([IndexedObject])
    end
  end

  describe ".configured?(name)" do

    before :each do
      XapianDb::DocumentBlueprint.reset
    end

    it "returns true, if a blueprint with the given name is configured" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.index :id
        blueprint.index :name
      end
      expect(XapianDb::DocumentBlueprint.configured?(:IndexedObject)).to be_truthy
    end

    it "returns false, if no blueprints are configured" do
      expect(XapianDb::DocumentBlueprint.configured?(:IndexedObject)).to be_falsey
    end

    it "returns false, if a blueprint with the given name is not configured" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.index :id
        blueprint.index :name
      end
      expect(XapianDb::DocumentBlueprint.configured?(:NotConfigured)).to be_falsey
    end
  end

  describe ".blueprint_for(name)" do

    before :each do
      XapianDb::DocumentBlueprint.reset
    end

    it "returns the blueprint for a class" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.index :id
        blueprint.index :name
      end
      expect(XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject)).to be_a_kind_of XapianDb::DocumentBlueprint
    end

    it "returns the blueprint for the super class if no specific blueprint is configured" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.index :id
        blueprint.index :name
      end
      class InheritedIndexedObject < IndexedObject; end
      expect(XapianDb::DocumentBlueprint.blueprint_for(:InheritedIndexedObject)).to eq(XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject))
    end

    it "can handle namespaces" do
      XapianDb::DocumentBlueprint.setup("Namespace::IndexedObject") do |blueprint|
        blueprint.index :id
        blueprint.index :name
      end
      expect(XapianDb::DocumentBlueprint.blueprint_for("Namespace::IndexedObject")).to be_a_kind_of XapianDb::DocumentBlueprint
    end

    it "returns nil if there is no blueprint configuration for a class" do
      expect(XapianDb::DocumentBlueprint.blueprint_for(:Object)).not_to be
    end

    it "returns nil if there is no blueprint configuration at all" do
      expect(XapianDb::DocumentBlueprint.blueprint_for(:Object)).not_to be
    end

    it "accepts a string for the class name" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.index :id
        blueprint.index :name
      end
      expect(XapianDb::DocumentBlueprint.blueprint_for("IndexedObject")).to be_a_kind_of XapianDb::DocumentBlueprint
    end

    it "accepts a symbol for the class name" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.index :id
        blueprint.index :name
      end
      expect(XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject)).to be_a_kind_of XapianDb::DocumentBlueprint
    end
  end

  describe ".dependencies_for(klass_name, changed_attrs)" do

    it "returns dependency objects that match the klass name" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.index :id
        blueprint.index :name
      end

      XapianDb::DocumentBlueprint.setup(:OtherIndexedObject) do |blueprint|
        blueprint.index :id
        blueprint.index :name

        blueprint.dependency :IndexedObject do |person|
        end
      end

      expect(XapianDb::DocumentBlueprint.dependencies_for('IndexedObject', []).size).to eq(1)
    end

    it "returns dependency objects that match the klass name and the attributes they're interested in, when specified" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.index :id
        blueprint.index :name
      end

      XapianDb::DocumentBlueprint.setup(:OtherIndexedObject) do |blueprint|
        blueprint.index :id
        blueprint.index :name

        blueprint.dependency :IndexedObject, when_changed: %i(name) do |person|
        end
      end

      expect(XapianDb::DocumentBlueprint.dependencies_for 'IndexedObject', []).to be_empty # no change for name
      expect(XapianDb::DocumentBlueprint.dependencies_for('IndexedObject', ['name']).size).to eq(1)
    end
  end

  describe ".searchable_prefixes" do

    it "should return an array of all method names configured to be indexed" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.index :id
        blueprint.index :name
      end
      expect(XapianDb::DocumentBlueprint.searchable_prefixes).to include(:id, :name)
    end

    it "should return %w(indexed_class) if no attributes and no indexes are configured" do
      XapianDb::DocumentBlueprint.reset
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
      end
      expect(XapianDb::DocumentBlueprint.searchable_prefixes).to eq(%w(indexed_class))
    end
  end

  describe ".attributes" do

    it "should return an array of all defined attributes" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attribute :id
        blueprint.attribute :name
      end
      expect(XapianDb::DocumentBlueprint.attributes).to include(:id, :name)
    end

    it "should return an empty array if no attributes are configured" do
      XapianDb::DocumentBlueprint.reset
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.index :id
        blueprint.index :name
      end
      expect(XapianDb::DocumentBlueprint.attributes).to eq([])
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
      expect(XapianDb::DocumentBlueprint.type_info_for(:date)).to eq(:date)
    end

    it "should return :string if no type is defined" do
      expect(XapianDb::DocumentBlueprint.type_info_for(:untyped)).to eq(:string)
    end

    it "returns nil if the attribute is not defined" do
      expect(XapianDb::DocumentBlueprint.type_info_for(:not_defined)).not_to be
    end

    it "returns nil if no blueprints are defined defined" do
      XapianDb::DocumentBlueprint.reset
      expect(XapianDb::DocumentBlueprint.type_info_for(:not_defined)).not_to be
    end
  end

  describe ".setup (class)" do
    it "stores a blueprint for a given class" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject)
      expect(XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject)).to be_a_kind_of(XapianDb::DocumentBlueprint)
    end

    it "does replace the blueprint for a class if the class is reloaded" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject)
      expect(XapianDb::DocumentBlueprint.configured_classes.size).to eq(1)
      # reload IndexedObject
      Object.send(:remove_const, :IndexedObject)
      load File.expand_path('../../basic_mocks.rb', __FILE__)
      XapianDb::DocumentBlueprint.setup(:IndexedObject)
      expect(XapianDb::DocumentBlueprint.configured_classes.size).to eq(1)
    end

    it "raises an exception if a method with the same name has different type declarations" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attribute :date, :as => :date
      end
      expect { XapianDb::DocumentBlueprint.setup(:OtherIndexedObject) do |blueprint|
        blueprint.attribute :date, :as => :number
      end }.to raise_error ArgumentError
    end

    it "allows blueprint definitions with symbols" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject)
      expect(XapianDb::DocumentBlueprint.blueprint_for('IndexedObject')).not_to be_nil
    end

    it "allows blueprint definitions with strings" do
      XapianDb::DocumentBlueprint.setup('IndexedObject')
      expect(XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject)).not_to be_nil
    end

    it "lazy-loads blueprint classes" do
      expect do
        XapianDb::DocumentBlueprint.setup(:NotYetLoadedClass)
        class NotYetLoadedClass; end
      end.not_to raise_error
      expect(XapianDb::DocumentBlueprint.blueprint_for(:NotYetLoadedClass)).not_to be_nil
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
      expect(XapianDb::DocumentBlueprint.value_number_for(:name)).to eq(@position_offset + 1)
    end

    it "accepts a string as an argument" do
      expect(XapianDb::DocumentBlueprint.value_number_for("name")).to eq(@position_offset + 1)
    end

    it "raises an argument error if the method is not indexed" do
      expect { XapianDb::DocumentBlueprint.value_number_for(:not_indexed) }.to raise_error ArgumentError
    end

    it "raises an argument error if no blueprints are defined" do
      XapianDb::DocumentBlueprint.reset
      XapianDb::DocumentBlueprint.instance_variable_set(:@attributes, nil)
      expect { XapianDb::DocumentBlueprint.value_number_for(:not_indexed) }.to raise_error ArgumentError
    end

    it "handles multiple blueprints whith the same indexed method at different positions" do
      XapianDb::DocumentBlueprint.setup(:OtherIndexedObject) do |blueprint|
        blueprint.index :id
        blueprint.index :not_in_alphabetical_order
        blueprint.index :name
      end
      expect(XapianDb::DocumentBlueprint.value_number_for(:name)).to eq(@position_offset + 1)
    end

    it "returns 0 for :indexed_class" do
      expect(XapianDb::DocumentBlueprint.value_number_for(:indexed_class)).to eq(0)
    end

    it "calculates the value number in alphabetical order even if the attributes are not declared in alphabetical order" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attribute :date_of_birth, :as => :date
        blueprint.attribute :empty_field
        blueprint.attribute :id
        blueprint.attribute :name
        blueprint.attribute :array
      end
      expect(XapianDb::DocumentBlueprint.value_number_for(:array)).to eq(@position_offset)
    end
  end

  describe "#adapter (symbol)" do
    it "overides the adapter for the configured class" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.adapter :generic
      end
      expect(XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject)._adapter).to be_equal XapianDb::Adapters::GenericAdapter
    end
  end

  describe "#_adapter" do

    it "returns the generic adapter if no configration is present" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attribute :name
      end
      expect(XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject)._adapter).to be_equal XapianDb::Adapters::GenericAdapter
    end

    it "returns the globally configured adapter if specified" do
      allow(XapianDb::Config).to receive(:adapter).and_return(XapianDb::Adapters::ActiveRecordAdapter)
      XapianDb::DocumentBlueprint.setup(:ActiveRecordObject) do |blueprint|
        blueprint.attribute :name
      end
      expect(XapianDb::DocumentBlueprint.blueprint_for(:ActiveRecordObject)._adapter).to be_equal XapianDb::Adapters::ActiveRecordAdapter
    end

    it "returns the adapter configured for this blueprint if specified" do
      XapianDb::DocumentBlueprint.setup(:DatamapperObject) do |blueprint|
        blueprint.adapter :datamapper
        blueprint.attribute :name
      end
      expect(XapianDb::DocumentBlueprint.blueprint_for(:DatamapperObject)._adapter).to be_equal XapianDb::Adapters::DatamapperAdapter
    end
  end

  describe "#autoindex(boolean)" do
    it "turns auto-indexing on or off for this blueprint" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.autoindex false
      end
      expect(XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject).autoindex?).to be_falsey
    end

    it "is true by default" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
      end
      expect(XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject).autoindex?).to be_truthy
    end
  end

  describe "#attribute" do

    before :each do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attribute :id
      end
    end

    it "adds an attribute to the blueprint" do
      expect(XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject).attribute_names).to include(:id)
    end

    it "adds the attribute to the indexed methods by default" do
      expect(XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject).indexed_method_names).to include(:id)
    end

    it "does not index the attribute if the :index option ist set to false" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attribute :id, :index => false
      end
      expect(XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject).indexed_method_names).not_to include(:id)
    end

    it "allows to specify a weight for the attribute" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attribute :id, :weight=> 10
      end
      expect(XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject).options_for_indexed_method(:id).weight).to eq(10)
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
      expect(XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject).attribute_names).to include(:complex)
    end

    it "allows to specify if the attribute should be prefixed" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attribute :id, :prefixed => false
      end
      expect(XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject).options_for_indexed_method(:id).prefixed).to be_falsey
    end

    it "throws an exception if the attribute name maps to a Xapian::Document method name" do
      expect(XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject).attribute_names).to include(:id)
      expect{XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attribute :data
      end}.to raise_error ArgumentError
    end
  end

  describe "#attributes" do

    it "allows to declare one single attribute" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attributes :id
      end
      expect(XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject).attribute_names).to include(:id)
    end

    it "allows to declare multiple attributes in a single statement (but without options)" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attributes :id, :name, :first_name
      end
      expect(XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject).attribute_names).to include(:id, :name, :first_name)
    end

    it "throws an exception if the attribute name maps to a Xapian::Document method name" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attributes :id, :name, :first_name
      end
      expect(XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject).attribute_names).to include(:id)
      expect{XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attributes :data
      end}.to raise_error ArgumentError
    end
  end

  describe "#index" do

    before :each do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.index :id
      end
    end

    it "adds an indexed value to the blueprint" do
      expect(XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject).options_for_indexed_method(:id)).to be_a_kind_of XapianDb::DocumentBlueprint::IndexOptions
    end

    it "defaults the weight option to 1" do
      expect(XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject).options_for_indexed_method(:id).weight).to eq(1)
    end

    it "accepts weight as an option" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.index :id, :weight => 10
      end
      expect(XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject).options_for_indexed_method(:id).weight).to eq(10)
    end

    it "does not accept a type option" do
      expect { XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.index :date, :as => :date
      end }.to raise_error ArgumentError
    end

    it "allows to declare two methods (can distinguish this from a method with an options hash)" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.index :id, :name
      end
      expect(XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject).indexed_method_names).to include(:id, :name)
    end

    it "allows to declare multiple methods (but without options)" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.index :id, :name, :first_name
      end
      expect(XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject).indexed_method_names).to include(:id, :name, :first_name)
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
      expect(XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject).instance_variable_get(:@ignore_expression)).to be_a_kind_of Proc
    end
  end

  describe "#should_index? obj" do

    it "should return true if no ignore expression is given" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attribute :id
      end
      blueprint = XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject)
      obj = IndexedObject.new 1
      expect(blueprint.should_index?(obj)).to be_truthy
    end

    it "should return false if the ignore expression evaluates to true" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attribute :id
        blueprint.ignore_if {id == 1}
      end
      blueprint = XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject)
      obj = IndexedObject.new 1
      expect(blueprint.should_index?(obj)).to be_falsey
    end

    it "should return true if the ignore expression evaluates to false" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attribute :id
        blueprint.ignore_if {id == 2}
      end
      blueprint = XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject)
      obj = IndexedObject.new 1
      expect(blueprint.should_index?(obj)).to be_truthy
    end
  end

  describe "base_query" do

    it "accepts a base query expression" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attribute :array
        blueprint.base_query ActiveRecordObject.includes(:children)
      end
      expect(XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject).lazy_base_query).to be
    end

    it "converts an explicit base query expression to a proc" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attribute :array
        blueprint.base_query ActiveRecordObject.includes(:children)
      end
      expect(XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject).lazy_base_query).to be_a Proc
    end

    it "accepts a base query expression inside a block" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attribute :array
        blueprint.base_query { ActiveRecordObject.includes(:children) }
      end
      expect(XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject).lazy_base_query).to be_a Proc
    end
  end

  describe "#natural_sort_order" do

    it "defaults to id if not specified" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
      end
      expect(XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject)._natural_sort_order).to eq(:id)
    end

    it "accepts a method symbol" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.natural_sort_order :name
      end
      expect(XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject)._natural_sort_order).to eq(:name)
    end

    it "accepts a block" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.natural_sort_order do
          @id
        end
      end
      expect(XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject)._natural_sort_order).to be_a Proc
    end

    it "raises an ArgumentError, if a method name AND a block are given" do
      expect { XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.natural_sort_order :name do
          @id
        end
      end }.to raise_error ArgumentError
    end
  end

  describe "#dependency(klass_name, when_changed: [], &block)" do

    it "adds a dependency to the blueprint" do
      dependent_object = OtherIndexedObject.new 1
      blueprint = XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.index :id
        blueprint.index :name

        blueprint.dependency :OtherIndexedObject, when_changed: %i(name) do |person|
          [dependent_object]
        end
      end

      expect(blueprint.dependencies.size).to eq(1)
      dependency = blueprint.dependencies.first
      expect(dependency.dependent_on).to eq 'OtherIndexedObject'
      expect(dependency.trigger_attributes).to eq ['name']
      expect(dependency.block.call).to eq [dependent_object]
    end
  end

  describe "#accessors_module" do

    before :each do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attribute :array, as: :json
        blueprint.attribute :date_of_birth, :as => :date
        blueprint.attribute :empty_field
        blueprint.attribute :id, as: :integer
        blueprint.attribute :name
      end
      @blueprint = XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject)

      @doc = Xapian::Document.new
      @doc.add_value(0, "IndexedObject")
      @doc.add_value(XapianDb::DocumentBlueprint.value_number_for(:array), [1, "two", Date.new(2011, 1, 1)].to_json)
      @doc.add_value(XapianDb::DocumentBlueprint.value_number_for(:date_of_birth), "20110101")
      @doc.add_value(XapianDb::DocumentBlueprint.value_number_for(:empty_field), nil.to_s)
      @doc.add_value(XapianDb::DocumentBlueprint.value_number_for(:id), Xapian::sortable_serialise(1))
      @doc.add_value(XapianDb::DocumentBlueprint.value_number_for(:name), "Kogler")
      @doc.extend @blueprint.accessors_module
    end

    it "builds an accessor module for the blueprint" do
      expect(@blueprint.accessors_module).to be_a_kind_of Module
    end

    it "adds accessor methods for each configured field" do
      expect(@blueprint.accessors_module.instance_methods).to include(:id, :name, :date_of_birth)
    end

    it "adds accessor methods that can handle nil" do
      expect(@doc.empty_field).to eq("")
    end

    it "adds an accessor method for the class of the indexed object" do
      expect(@doc.indexed_class).to eq("IndexedObject")
    end

    it "adds accessor methods that deserialize values to native objects" do
      expect(@doc.date_of_birth).to eq(Date.new(2011, 1, 1))
    end

    it "adds a method to access the document attributes as a hash" do
      expect(@doc.attributes).to eq({ "array"         => [1, "two", "2011-01-01"],
                                  "date_of_birth" => Date.new(2011, 1, 1),
                                  "empty_field"   => "",
                                  "id"            => 1,
                                  "name"          => "Kogler" })
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
      expect(blueprint.type_map).to be_a Hash
    end

    it "contains the type of an indexed method if a type is defined" do
      expect(blueprint.type_map[:date]).to eq(:date)
    end

    it "contains :string for an indexed method if no type is defined" do
      expect(blueprint.type_map[:untyped]).to eq(:string)
    end
  end
end
