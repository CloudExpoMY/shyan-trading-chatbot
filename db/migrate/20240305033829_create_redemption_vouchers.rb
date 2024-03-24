class CreateRedemptionVouchers < ActiveRecord::Migration[7.1]
  def change
    create_table :redemption_vouchers do |t|
      t.string :description
      t.string :code
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
