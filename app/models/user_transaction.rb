class UserTransaction < ActiveRecord::Base
  belongs_to :user
  
  def self.create_from_transaction(transaction_params)
    create(transaction_params)
  end
end
