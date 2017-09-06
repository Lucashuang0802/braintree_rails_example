class PaymentController < ApplicationController
  TRANSACTION_SUCCESS_STATUSES = [
    Braintree::Transaction::Status::Authorizing,
    Braintree::Transaction::Status::Authorized,
    Braintree::Transaction::Status::Settled,
    Braintree::Transaction::Status::SettlementConfirmed,
    Braintree::Transaction::Status::SettlementPending,
    Braintree::Transaction::Status::Settling,
    Braintree::Transaction::Status::SubmittedForSettlement,
  ]

  skip_before_action :verify_authenticity_token

  def new
    @client_token = Braintree::ClientToken.generate
    render json: {"client_token": @client_token}
  end

  def create
    data = JSON.parse( request.body.read.to_s )
    amount = data["amount"] # In production you should not take amounts directly from clients
    nonce = data["payment_method_nonce"]
    result = Braintree::Transaction.sale(
      amount: amount,
      payment_method_nonce: nonce,
      :options => {
        :submit_for_settlement => true
      }
    )

    if result.success? || result.transaction
      render json: {"success": result.transaction.id}
    else
      error_messages = result.errors.map { |error| "Error: #{error.code}: #{error.message}" }
      render json: {"error": error_messages}
    end
  end

end
