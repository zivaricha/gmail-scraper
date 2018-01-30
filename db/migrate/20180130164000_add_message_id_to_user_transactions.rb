class AddMessageIdToUserTransactions < ActiveRecord::Migration
  def change
    add_column :user_transactions, :message_id, :string
    add_index :user_transactions, :message_id
  end
end
