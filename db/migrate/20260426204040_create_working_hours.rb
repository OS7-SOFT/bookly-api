class CreateWorkingHours < ActiveRecord::Migration[8.1]
  def change
    create_table :working_hours do |t|
      t.references :business, null: false, foreign_key: true

      t.integer :day_of_week, null: false
      t.time :start_time
      t.time :end_time
      t.boolean :is_closed, null: false, default: false

      t.timestamps
    end

    add_index :working_hours,
              [ :business_id, :day_of_week ],
              unique: true
  end
end
