class UserTransactionsController < ApplicationController
  def index
    @user_transactions = UserTransaction.where(user_id: current_user.id)
  end
end
