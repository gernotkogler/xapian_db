module XapianDb
  module ModelExtenders
    module ActiveRecord
      def inherited(klass)
        super
        if XapianDb::DocumentBlueprint.configured? klass.name
          blueprint = XapianDb::DocumentBlueprint.blueprint_for klass.name
          blueprint._adapter.add_class_helper_methods_to klass
        end
      end
    end
  end
end
