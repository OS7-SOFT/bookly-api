class CreateBusinesses < ActiveRecord::Migration[8.1]
  def change
    create_table :businesses do |t|
      t.references :user, null: false, foreign_key: true

      t.string :name, null: false
      t.text :description
      t.string :phone
      t.string :email
      t.string :address
      t.boolean :is_active, null: false, default: true

      t.timestamps
    end

    add_index :businesses, :is_active
  end
end
