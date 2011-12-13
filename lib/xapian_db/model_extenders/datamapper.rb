module DataMapper
  module Resource

    class << self
      alias_method :included_dm, :included
    end

    def self.included(model)
      included_dm model
      if XapianDb::DocumentBlueprint.configured? model.name
        blueprint = XapianDb::DocumentBlueprint.blueprint_for model.name
        blueprint._adapter.add_class_helper_methods_to model
      end
    end
  end
end
