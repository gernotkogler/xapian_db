# encoding: utf-8

# A document blueprint describes the mapping of an object to a Xapian document
# for a given class.
# @author Gernot Kogler

module XapianDb
    
  class DocumentBlueprint

    # ---------------------------------------------------------------------------------   
    # Singleton Implementation
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
        yield blueprint if block_given?
        @blueprints[klass] = blueprint
        adapter = blueprint.adapter || @default_adapter || Adapters::DatamapperAdapter
        adapter.add_helper_methods_to klass
      end
      
      # Get the blueprint for a class
      def blueprint_for(klass)
        @blueprints[klass]
      end
            
    end
    
    # ---------------------------------------------------------------------------------   
    # Blueprint DSL
    # ---------------------------------------------------------------------------------   
    attr_reader :adapter
    
    def adapter=(adapter)
      @adapter = adapter
    end

  end
  
end