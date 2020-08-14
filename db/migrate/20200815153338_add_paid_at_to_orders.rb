class AddPaidAtToOrders < ActiveRecord::Migration[5.2]
  def change
    change_table :orders do |t|
      t.datetime :paid_at
    end
  end
end
