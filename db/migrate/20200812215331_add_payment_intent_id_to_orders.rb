class AddPaymentIntentIdToOrders < ActiveRecord::Migration[5.2]
  def change
    change_table :orders do |t|
      t.string :payment_intent_id
    end
  end
end
