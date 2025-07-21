class CreateCompanies < ActiveRecord::Migration[7.2]
  def change
    create_table :companies do |t|
      t.string :name

      t.timestamps
    end
    add_index :companies, :name, unique: true
    add_index :companies, 'lower(name)', unique: true
  end
end
