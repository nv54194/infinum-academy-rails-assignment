class AddLowerNameIndexToCompanies < ActiveRecord::Migration[7.2]
  def change
    add_index :companies, 'lower(name)', unique: true
  end
end
