class CreateBookableServices < ActiveRecord::Migration[8.1]
  def change
    create_table :bookable_services do |t|
      t.references :business, null: false, foreign_key: true

      t.string :name, null: false
      t.text :description
      t.integer :duration_minutes, null: false
      t.decimal :price, precision: 10, scale: 2, null: false, default: 0
      t.boolean :is_active, null: false, default: true

      t.timestamps
    end

    add_index :bookable_services, [ :business_id, :is_active ]
  end
end
