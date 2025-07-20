class CreateFlights < ActiveRecord::Migration[7.2]
  def change
    create_table :flights do |t|
      t.string :name, null: false
      t.integer :no_of_seats
      t.decimal :base_price, null: false
      t.datetime :departs_at, null: false
      t.datetime :arrives_at, null: false
      t.references :company, null: false, foreign_key: true, index: true

      t.timestamps
    end
  end
end