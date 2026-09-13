require "test_helper"

class OrderTest < ActiveSupport::TestCase
  test "generates a unique order_number on create" do
    order = Order.create!(
      product: products(:cooking_class), unit_price: 35.00, total_amount: 35.00,
      guest_first_name: "Ada", guest_last_name: "Lovelace", guest_email: "ada@example.com"
    )

    assert order.order_number.present?
    assert_equal 12, order.order_number.length
  end

  test "build_from_product! reads the price from the database, not from the caller" do
    order = Order.build_from_product!(
      product: products(:cooking_class),
      guest_attributes: { guest_first_name: "Ada", guest_last_name: "Lovelace", guest_email: "ada@example.com" },
      quantity: 2
    )

    assert_equal 35.00, order.unit_price.to_f
    assert_equal 70.00, order.total_amount.to_f
  end

  test "build_from_product! refuses a non-purchasable product" do
    assert_raises(ArgumentError) do
      Order.build_from_product!(
        product: products(:not_yet_on_sale),
        guest_attributes: { guest_first_name: "Ada", guest_last_name: "Lovelace", guest_email: "ada@example.com" }
      )
    end
  end

  test "mark_paid! is idempotent" do
    order = orders(:pending_order)
    order.mark_paid!(nexi_transaction_id: "ABC123", nexi_authorization_code: "000111")
    paid_at = order.paid_at

    order.mark_paid!(nexi_transaction_id: "SHOULD_NOT_OVERWRITE")

    assert_equal "ABC123", order.reload.nexi_transaction_id
    assert_equal paid_at.to_i, order.paid_at.to_i
  end
end
