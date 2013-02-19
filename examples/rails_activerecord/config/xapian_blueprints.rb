# Index configuration for XapianDb

XapianDb::DocumentBlueprint.setup(:Person) do |blueprint|
  blueprint.attribute :name,             :weight => 10
  blueprint.attribute :first_name,       :weight => 10
  blueprint.attribute :date_of_birth, as: :date
  blueprint.attribute :address, as: :json

  blueprint.index     :notes
end
