# encoding: utf-8

# A document blueprint describes the mapping of an object to a Xapian document
# for a given class.
# @author Gernot Kogler

module XapianDb
    
  class DocumentBlueprint

    # ---------------------------------------------------------------------------------   
    # Singleton methods
    # ---------------------------------------------------------------------------------   
    class << self

      # Set the default adapter for all indexed classes
      def default_adapter=(klass)
        @default_adapter = klass
      end
      
      # Configure the blueprint for a class
      def setup(klass, &block)
        @blueprints ||= {}
        blueprint = DocumentBlueprint.new
        blueprint.indexer = Indexer.new(blueprint)
        yield blueprint if block_given? # Configure the blueprint through the block
        @blueprints[klass] = blueprint
        adapter = blueprint.adapter || @default_adapter || Adapters::DatamapperAdapter
        adapter.add_helper_methods_to klass
      end
      
      # Get the blueprint for a class
      def blueprint_for(klass)
        @blueprints[klass] if @blueprints
      end
            
    end
    
    # ---------------------------------------------------------------------------------   
    # Blueprint DSL methods
    # ---------------------------------------------------------------------------------   
    attr_reader :adapter, :fields, :indexed_values
    attr_accessor :indexer
        
    # Construct the blueprint
    def initialize
      @fields = []
      @indexed_values = {}
    end
    
    # Set a custom adapter for this blueprint
    def adapter=(adapter)
      @adapter = adapter
    end
    
    # Add a field to the list
    # TODO: Make sure the name does not collide with a method name of Xapian::Document since
    # we generate methods in the documents for all defined fields
    def field(name, options={})
      @fields << name
    end

    # Add an indexed value to the list
    def text(name, options={})
      @indexed_values[name] = TextOptions.new(options)
    end

    # Options for an indexed text
    class TextOptions      
      attr_accessor :weight
      
      def initialize(options)
        @weight = options[:weight] || 1
      end
    end
          
  end
  
end