class CreatePeople < ActiveRecord::Migration
  def self.up
    create_table :people do |t|
      t.string  :name
      t.string  :first_name
      t.date    :date_of_birth
      t.string  :language
      t.integer :address_id
      t.text    :notes
      t.timestamps
    end
  end

  def self.down
    drop_table :people
  end
end
