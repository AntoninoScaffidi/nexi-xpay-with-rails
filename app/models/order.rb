class Order < ApplicationRecord
  VALID_EMAIL_REGEX = /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/

  belongs_to :product
  has_many :order_payment_notifications, dependent: :destroy

  enum :status, { pending_payment: 0, paid: 1, payment_failed: 2, cancelled: 3, refunded: 4 }

  STATUS_LABELS = {
    "pending_payment" => "Waiting for payment",
    "paid" => "Paid",
    "payment_failed" => "Payment failed",
    "cancelled" => "Cancelled",
    "refunded" => "Refunded"
  }.freeze

  before_validation :generate_order_number, on: :create

  validates :order_number, presence: true, uniqueness: true
  validates :unit_price, :total_amount, numericality: { greater_than: 0 }
  validates :quantity, numericality: { greater_than: 0 }
  validates :guest_first_name, :guest_last_name, presence: true
  validates :guest_email, presence: true, format: { with: VALID_EMAIL_REGEX }

  # The route param is :order_number, never the sequential id, in public URLs.
  def to_param
    order_number
  end

  def status_label
    STATUS_LABELS.fetch(status, status.humanize)
  end

  def guest_name
    "#{guest_first_name} #{guest_last_name}".strip
  end

  # Idempotent: a second call on an already-paid order is a no-op.
  def mark_paid!(nexi_transaction_id: nil, nexi_authorization_code: nil, nexi_raw_response: nil)
    return if paid?

    update!(
      status: :paid, paid_at: Time.current,
      nexi_transaction_id: nexi_transaction_id || self.nexi_transaction_id,
      nexi_authorization_code: nexi_authorization_code || self.nexi_authorization_code,
      nexi_raw_response: nexi_raw_response || self.nexi_raw_response
    )
  end

  # The only place that reads the price from the database and computes the total.
  def self.build_from_product!(product:, guest_attributes:, quantity: 1)
    raise ArgumentError, "Product is not purchasable" unless product.purchasable?

    unit_price = product.price
    quantity = quantity.to_i

    create!(
      product: product, quantity: quantity, unit_price: unit_price,
      total_amount: unit_price * quantity,
      **guest_attributes
    )
  end

  private

  def generate_order_number
    self.order_number ||= loop do
      candidate = SecureRandom.alphanumeric(12).upcase
      break candidate unless Order.exists?(order_number: candidate)
    end
  end
end
