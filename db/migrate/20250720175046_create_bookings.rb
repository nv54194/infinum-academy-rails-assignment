class CreateBookings < ActiveRecord::Migration[7.2]
  def change
    create_table :bookings do |t|
      t.integer :no_of_seats, null: false
      t.integer :seat_price, null: false
      t.references :user, null: false, foreign_key: true, index: true
      t.references :flight, null: false, foreign_key: true, index: true

      t.timestamps
    end
  end
end
