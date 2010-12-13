# encoding: utf-8

module XapianDb

  # A document blueprint describes the mapping of an object to a Xapian document
  # for a given class.
  # @example A simple document blueprint configuration for the class Person
  #   XapianDb::DocumentBlueprint.setup(Person) do |blueprint|
  #     # Our Person class has a method lang_cd. We use this method to
  #     # index each person with its language
  #     blueprint.language_method :lang_cd
  #     blueprint.attribute       :name, :weight => 10
  #     blueprint.attribute       :first_name
  #     blueprint.index           :remarks
  #   end
  # @example A document blueprint configuration with a complex attribute for the class Person
  #   XapianDb::DocumentBlueprint.setup(Person) do |blueprint|
  #     # Our Person class has a method lang_cd. We use this method to
  #     # index each person with its language
  #     blueprint.language_method :lang_cd
  #     blueprint.attribute       :complex, :weight => 10 do
  #       # add some logic here to evaluate the value of 'complex'
  #     end
  #   end
  # @author Gernot Kogler
  class DocumentBlueprint

    # ---------------------------------------------------------------------------------
    # Singleton methods
    # ---------------------------------------------------------------------------------
    class << self

      # Configure the blueprint for a class.
      # Available options:
      # - language_method (see {#language_method} for details)
      # - adapter (see {#adapter} for details)
      # - attribute (see {#attribute} for details)
      # - index (see {#index} for details)
      def setup(klass, &block)
        @blueprints ||= {}
        blueprint = DocumentBlueprint.new
        yield blueprint if block_given? # configure the blueprint through the block
        @blueprints[klass] = blueprint
        @adapter = blueprint.adapter || XapianDb::Config.adapter || Adapters::GenericAdapter
        @adapter.add_class_helper_methods_to klass
        @searchable_prefixes = nil # force rebuild of the searchable prefixes
      end

      # Get the blueprint for a class
      # @return [DocumentBlueprint]
      def blueprint_for(klass)
        @blueprints[klass] if @blueprints
      end

      # Return an array of all configured text methods in any blueprint
      # @return [Array<String>] All searchable prefixes
      def searchable_prefixes
        return [] unless @blueprints
        return @searchable_prefixes unless @searchable_prefixes.nil?
        prefixes = []
        @blueprints.values.each do |blueprint|
          prefixes << blueprint.searchable_prefixes
        end
        @searchable_prefixes = prefixes.flatten.compact.uniq
        # We can always do a field search on the name of the indexed class
        @searchable_prefixes << "indexed_class"
      end

    end

    # ---------------------------------------------------------------------------------
    # Instance methods
    # ---------------------------------------------------------------------------------

    # Return an array of all configured text methods in this blueprint
    # @return [Array<String>] All searchable prefixes
    def searchable_prefixes
      @prefixes ||= indexed_methods_hash.keys
    end

    # Lazily build and return a module that implements accessors for each field
    # @return [Module] A module containing all accessor methods
    def accessors_module
      return @accessors_module unless @accessors_module.nil?
      @accessors_module = Module.new

      # Add the accessor for the indexed class
      @accessors_module.instance_eval do
        define_method :indexed_class do
          self.values[0].value
        end
      end

      @attributes_hash.keys.each_with_index do |field, index|
        @accessors_module.instance_eval do
          define_method field do
            YAML::load(self.values[index+1].value)
          end
        end
      end
      # Let the adapter add its document helper methods (if any)
      adapter = @adapter || XapianDb::Config.adapter || XapianDb::Adapters::GenericAdapter
      adapter.add_doc_helper_methods_to(@accessors_module)
      @accessors_module
    end

    # ---------------------------------------------------------------------------------
    # Blueprint DSL methods
    # ---------------------------------------------------------------------------------

    # The name of the method that returns an iso language code. The
    # configured class must implement this method.
    attr_reader :lang_method

    # Collection of the configured attribute methods
    # @return [Array<Symbol>] The names of the configured attribute methods
    attr_reader :attributes_hash

    # Collection of the configured index methods
    # @return [Hash<Symbol, IndexOptions>] A hashtable containing all index methods as
    #   keys and IndexOptions as values
    attr_reader :indexed_methods_hash

    # Set / read a custom adapter.
    # Use this configuration option if you need a specific adapter for an indexed class.
    # If set, it overrides the globally configured adapter (see also {Config#adapter})
    attr_accessor :adapter

    # Construct the blueprint
    def initialize
      @attributes_hash = {}
      @indexed_methods_hash = {}
    end

    # Set the name of the method to get the language for an indexed object
    # @param [Symbol] lang The method name. The method must return an iso language code (:en, :de, ...)
    #   see LANGUAGE_MAP for the supported lanugaes
    def language_method(lang)
      @lang_method = lang
    end

    # Add an attribute to the blueprint. Attributes will be stored in the xapian documents an can be
    # accessed from a search result.
    # @param [String] name The name of the method that delivers the value for the attribute
    # @param [Hash] options
    # @option options [Integer] :weight (1) The weight for this attribute.
    # @option options [Boolean] :index (true) Should the attribute be indexed?
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
    # @todo Make sure the name does not collide with a method name of Xapian::Document
    def attribute(name, options={}, &block)
      opts = {:index => true}.merge(options)
      if block_given?
        @attributes_hash[name] = block
      else
        @attributes_hash[name] = nil
      end
      self.index(name, opts, &block) if opts[:index]
    end

    # Add list of attributes to the blueprint. Attributes will be stored in the xapian documents an can be
    # accessed from a search result.
    # @param [Array] attributes An array of method names that deliver the values for the attributes
    # @todo Make sure the name does not collide with a method name of Xapian::Document
    def attributes(*attributes)
      attributes.each do |attr|
        @attributes_hash[attr] = nil
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
            @indexed_methods_hash[args.first] = IndexOptions.new(args.last.merge(:block => block))
          else
            add_indexes_from args
          end
        else # multiple arguments
          add_indexes_from args
      end
    end

    # Options for an indexed method
    class IndexOptions

      # The weight for the indexed value
      attr_accessor :weight, :block

      # Constructor
      # @param [Hash] options
      # @option options [Integer] :weight (1) The weight for the indexed value
      def initialize(options)
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

  end

end