class CreateOrderPaymentNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :order_payment_notifications do |t|
      t.references :order, null: false, foreign_key: true
      t.jsonb :raw_params, null: false
      t.boolean :mac_verified, null: false, default: false
      t.boolean :processed, null: false, default: false
      t.string :outcome

      t.timestamps
    end
  end
end
