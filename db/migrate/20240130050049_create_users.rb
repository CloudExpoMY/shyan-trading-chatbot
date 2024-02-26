class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :phone_number
      t.string :full_name
      t.string :email
      t.integer :points, default: 0

      t.timestamps
    end
  end
end
