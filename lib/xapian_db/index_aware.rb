module XapianDb
  module IndexAware
    def inherited(klass)
      super
      if XapianDb::DocumentBlueprint.configured? klass.name
        blueprint = XapianDb::DocumentBlueprint.blueprint_for klass.name
        adapter = blueprint._adapter || XapianDb::Config.adapter || Adapters::GenericAdapter
        adapter.add_class_helper_methods_to klass
      end
    end
  end
end
