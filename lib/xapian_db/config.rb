# encoding: utf-8

# Global configuration for XapianDb
# @author Gernot Kogler

module XapianDb
  
  class Config

    # ---------------------------------------------------------------------------------   
    # Singleton methods
    # ---------------------------------------------------------------------------------   
    class << self

      def setup(&block)
        @config = Config.new
        yield @config if block_given?
      end
      
      def database
        @config.database
      end
              
    end  

    # ---------------------------------------------------------------------------------   
    # DSL methods
    # ---------------------------------------------------------------------------------   
    attr_accessor :database
    
  end
  
end