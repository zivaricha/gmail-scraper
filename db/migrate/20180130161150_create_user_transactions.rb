class CreateUserTransactions < ActiveRecord::Migration
  def change
    create_table :user_transactions do |t|
      t.references :user, index: true, foreign_key: true
      t.string :product_name
      t.decimal :product_price
      t.string :seller_name
      t.datetime :date

      t.timestamps null: false
    end
  end
end
