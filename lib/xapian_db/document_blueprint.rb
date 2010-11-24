# encoding: utf-8

# A document blueprint describes the mapping of an object to a Xapian document
# for a given class.
# @author Gernot Kogler

module XapianDb
    
  class DocumentBlueprint
  
    # We use it as a singleton
    class << self

      # Configure a pattern to generate unique keys for any indexed object
      def define_unique_key_pattern(&block)
        @unique_key_pattern = block
      end
      
      # Configure the blueprint for a class
      def setup(klass, &block)
        @blueprints ||= {}
        blueprint = DocumentBlueprint.new
        yield blueprint if block_given?
        @blueprints[klass] = blueprint
        add_class_methods_to klass          
      end
      
      # Get the blueprint for a class
      def blueprint_for(klass)
        @blueprints[klass]
      end
      
      private

      # Add the helper methods to a configured class        
      def add_class_methods_to(klass)

        klass.instance_eval do
          define_method(:xapian_id) do
            @unique_key_pattern
          end
        end

      end
      
    end
  end
  
end