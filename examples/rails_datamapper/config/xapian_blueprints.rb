# Index configuration for XapianDb

XapianDb::DocumentBlueprint.setup(:Person) do |blueprint|
  blueprint.attribute :name,             :weight => 10
  blueprint.attribute :first_name,       :weight => 10
  blueprint.attribute :date_of_birth
  # We can use anything as an attribute or index argument
  # that is serializable by YAML, e.g. an associated model
  blueprint.attribute :address

  blueprint.index     :notes
end
