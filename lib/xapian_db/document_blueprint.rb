# encoding: utf-8

module XapianDb

  # A document blueprint describes the mapping of an object to a Xapian document
  # for a given class.
  # @example A simple document blueprint configuration for the class Person
  #   XapianDb::DocumentBlueprint.setup(Person) do |blueprint|
  #     blueprint.attribute       :name, :weight => 10
  #     blueprint.attribute       :first_name
  #     blueprint.index           :remarks
  #   end
  # @example A document blueprint configuration with a complex attribute for the class Person
  #   XapianDb::DocumentBlueprint.setup(Person) do |blueprint|
  #     blueprint.attribute       :complex, :weight => 10 do
  #       # add some logic here to evaluate the value of 'complex'
  #     end
  #   end
  # @author Gernot Kogler
  class DocumentBlueprint

    include XapianDb::Utilities

    # ---------------------------------------------------------------------------------
    # Singleton methods
    # ---------------------------------------------------------------------------------
    class << self

      # Configure the blueprint for a class.
      # Available options:
      # - adapter (see {#adapter} for details)
      # - attribute (see {#attribute} for details)
      # - index (see {#index} for details)
      def setup(klass, &block)
        @blueprints ||= {}
        blueprint = DocumentBlueprint.new
        yield blueprint if block_given? # configure the blueprint through the block
        validate_type_consistency_on blueprint
        # Remove a previously loaded blueprint for this class to avoid stale blueprint definitions
        @blueprints.delete_if { |indexed_class, blueprint| indexed_class.name == klass.name }
        @blueprints[klass] = blueprint
        @_adapter = blueprint._adapter || XapianDb::Config.adapter || Adapters::GenericAdapter
        @_adapter.add_class_helper_methods_to klass

        @searchable_prefixes = @blueprints.values.map { |blueprint| blueprint.searchable_prefixes }.flatten.compact.uniq || []
        # We can always do a field search on the name of the indexed class
        @searchable_prefixes << "indexed_class"
        @attributes = @blueprints.values.map { |blueprint| blueprint.attribute_names}.flatten.compact.uniq.sort || []
      end

      # Get all configured classes
      # @return [Array<Class>]
      def configured_classes
        @blueprints ? @blueprints.keys : []
      end

      # Get the blueprint for a class
      # @return [DocumentBlueprint]
      def blueprint_for(klass)
        if @blueprints
          key = klass
          while key != Object
            return @blueprints[key] unless @blueprints[key].nil?
            key = key.superclass
          end
          raise "Blueprint for class #{klass} is not defined"
        end
        raise "Blueprint for class #{klass} is not defined"
      end

      # Get the value number for an attribute. Please note that this is not the index in the values
      # array of a xapian document but the valueno. Therefore, document.values[value_number] returns
      # the wrong data, use document.value(value_number) instead.
      # @param [attribute] The name of an attribute
      # @return [Integer] The value number
      def value_number_for(attribute)
        raise ArgumentError.new "attribute #{attribute} is not configured in any blueprint" if @attributes.nil?
        return 0 if attribute.to_sym == :indexed_class
        position = @attributes.index attribute.to_sym
        if position
          # We add 1 because value slot 0 is reserved for the class name
          return position + 1
        else
          raise ArgumentError.new "attribute #{attribute} is not configured in any blueprint"
        end
      end

      # Get the type info of an attribute
      # @param [attribute] The name of an indexed method
      # @return [Symbol] The defined type or :untyped if no type is defined
      def type_info_for(attribute)
        return nil if @blueprints.nil?
        @blueprints.values.each do |blueprint|
          return blueprint.type_map[attribute] if blueprint.type_map.has_key?(attribute)
        end
        nil
      end

      # Return an array of all configured text methods in any blueprint
      # @return [Array<String>] All searchable prefixes
      def searchable_prefixes
        @searchable_prefixes
      end

      # Return an array of all defined attributes
      # @return [Array<Symbol>] All defined attributes
      def attributes
        @attributes
      end

      private

      def validate_type_consistency_on(blueprint)
        blueprint.type_map.each do |method_name, type|
          if type_info_for(method_name) && type_info_for(method_name) != type
            raise ArgumentError.new "ambigous type definition for #{method_name} detected (#{type_info_for(method_name)}, #{type})"
          end
        end
      end

    end

    # ---------------------------------------------------------------------------------
    # Instance methods
    # ---------------------------------------------------------------------------------

    attr_reader :type_map

    # Get the names of all configured attributes sorted alphabetically
    # @return [Array<Symbol>] The names of the attributes
    def attribute_names
      @attributes_hash.keys.sort
    end

    # Get the block associated with an attribute
    # @param [Symbol] attribute The name of the attribute
    # @return [Block] The block
    def block_for_attribute(attribute)
      @attributes_hash[attribute][:block]
    end

    # Get the names of all configured index methods sorted alphabetically
    # @return [Array<Symbol>] The names of the index_methods
    def indexed_method_names
      @indexed_methods_hash.keys.sort
    end

    # Get the options for an indexed method
    # @param [Symbol] method The name of the method
    # @return [IndexOptions] The options
    def options_for_indexed_method(method)
      @indexed_methods_hash[method]
    end

    # Return an array of all configured text methods in this blueprint
    # @return [Array<String>] All searchable prefixes
    def searchable_prefixes
      @searchable_prefixes ||= indexed_method_names
    end

    # Should the object go into the index? Evaluates an ignore expression,
    # if defined
    def should_index? obj
      return obj.instance_eval(&@ignore_expression) == false if @ignore_expression
      true
    end

    # Lazily build and return a module that implements accessors for each field
    # @return [Module] A module containing all accessor methods
    def accessors_module
      return @accessors_module unless @accessors_module.nil?
      @accessors_module = Module.new

      # Add the accessors for the indexed class and the score
      @accessors_module.instance_eval do

        define_method :indexed_class do
          self.values[0].value
        end

        define_method :score do
          @score
        end

      end

      # Add an accessor for each attribute
      attribute_names.each do |attribute|
        index = DocumentBlueprint.value_number_for(attribute)
        codec = XapianDb::TypeCodec.codec_for @type_map[attribute]
        @accessors_module.instance_eval do
          define_method attribute do
            codec.decode self.value(index)
          end
        end
      end

      # Let the adapter add its document helper methods (if any)
      adapter = @_adapter || XapianDb::Config.adapter || XapianDb::Adapters::GenericAdapter
      adapter.add_doc_helper_methods_to(@accessors_module)
      @accessors_module
    end

    # ---------------------------------------------------------------------------------
    # Blueprint DSL methods
    # ---------------------------------------------------------------------------------

    # An optional custom adapter
    attr_accessor :_adapter

    # Construct the blueprint
    def initialize
      @attributes_hash =      {}
      @indexed_methods_hash = {}
      @type_map =             {}
    end

    # Set the adapter
    # @param [Symbol] type The adapter type; the following adapters are available:
    #   - :generic ({XapianDb::Adapters::GenericAdapter})
    #   - :active_record ({XapianDb::Adapters::ActiveRecordAdapter})
    #   - :datamapper ({XapianDb::Adapters::DatamapperAdapter})
    def adapter(type)
      # We try to guess the adapter name
      @_adapter = XapianDb::Adapters.const_get("#{camelize(type.to_s)}Adapter")
    end

    # Add an attribute to the blueprint. Attributes will be stored in the xapian documents an can be
    # accessed from a search result.
    # @param [String] name The name of the method that delivers the value for the attribute
    # @param [Hash] options
    # @option options [Integer] :weight (1) The weight for this attribute.
    # @option options [Boolean] :index (true) Should the attribute be indexed?
    # @option options [Symbol] :as should add type info for range queries (:date, :numeric)
    # @example For complex attribute configurations you may pass a block:
    #   XapianDb::DocumentBlueprint.setup(IndexedObject) do |blueprint|
    #     blueprint.attribute :complex do
    #       if @id == 1
    #         "One"
    #       else
    #         "Not one"
    #       end
    #     end
    #   end
    def attribute(name, options={}, &block)
      raise ArgumentError.new("You cannot use #{name} as an attribute name since it is a reserved method name of Xapian::Document") if reserved_method_name?(name)
      do_not_index    = options.delete(:index) == false
      @type_map[name] = (options.delete(:as) || :generic)

      if block_given?
        @attributes_hash[name] = {:block => block}.merge(options)
      else
        @attributes_hash[name] = options
      end
      self.index(name, options, &block) unless do_not_index
    end

    # Add a list of attributes to the blueprint. Attributes will be stored in the xapian documents ans
    # can be accessed from a search result.
    # @param [Array] attributes An array of method names that deliver the values for the attributes
    def attributes(*attributes)
      attributes.each do |attr|
        raise ArgumentError.new("You cannot use #{attr} as an attribute name since it is a reserved method name of Xapian::Document") if reserved_method_name?(attr)
        @attributes_hash[attr] = {}
        @type_map[attr] = :generic
        self.index attr
      end
    end

    # Add an indexed value to the blueprint. Indexed values are not accessible from a search result.
    # @param [Array] args An array of arguments; you can pass a method name, an array of method names
    #   or a method name and an options hash.
    # @param [Block] &block An optional block for complex configurations
    # Avaliable options:
    # - :weight (default: 1) The weight for this indexed value
    # @example Simple index declaration
    #   blueprint.index :name
    # @example Index declaration with options
    #   blueprint.index :name, :weight => 10
    # @example Mass index declaration
    #   blueprint.index :name, :first_name, :profession
    # @example Index declaration with a block
    #   blueprint.index :complex, :weight => 10 do
    #     # add some logic here to calculate the value for 'complex'
    #   end
    def index(*args, &block)
      case args.size
        when 1
          @indexed_methods_hash[args.first] = IndexOptions.new(:weight => 1, :block => block)
        when 2
          # Is it a method name with options?
          if args.last.is_a? Hash
            options = args.last
            assert_valid_keys options, :weight
            @indexed_methods_hash[args.first] = IndexOptions.new(options.merge(:block => block))
          else
            add_indexes_from args
          end
        else # multiple arguments
          add_indexes_from args
      end
    end

    # Add a block of code that evaluates if a model should not be indexed
    def ignore_if &block
      @ignore_expression = block
    end

    # Options for an indexed method
    class IndexOptions

      attr_reader :weight, :block

      # Constructor
      # @param [Hash] options
      # @option options [Integer] :weight (1) The weight for the indexed value
      def initialize(options = {})
        @weight = options[:weight] || 1
        @block  = options[:block]
      end

    end

    private

    # Add index configurations from an array
    def add_indexes_from(array)
      array.each do |arg|
        @indexed_methods_hash[arg] = IndexOptions.new(:weight => 1)
      end
    end

    # Check if the attribute name does not collide with a method name of Xapian::Document
    def reserved_method_name?(attr_name)
      @reserved_method_names ||= Xapian::Document.instance_methods
      @reserved_method_names.include?(attr_name.to_sym)
    end

  end

end
