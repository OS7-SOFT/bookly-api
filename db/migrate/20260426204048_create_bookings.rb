class CreateBookings < ActiveRecord::Migration[8.1]
  def change
    create_table :bookings do |t|
      t.references :business, null: false, foreign_key: true
      t.references :bookable_service, null: false, foreign_key: true

      t.string :customer_name, null: false
      t.string :customer_phone, null: false
      t.string :customer_email

      t.datetime :start_at, null: false
      t.datetime :end_at, null: false

      t.integer :status, null: false, default: 0
      t.text :notes

      t.timestamps
    end

    add_index :bookings, [ :business_id, :start_at ]
    add_index :bookings, [ :business_id, :status ]
    add_index :bookings, [ :bookable_service_id, :start_at ]
    add_index :bookings, :customer_phone
  end
end
