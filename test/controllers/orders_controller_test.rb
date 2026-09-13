require "test_helper"

class OrdersControllerTest < ActionDispatch::IntegrationTest
  test "checkout ignores a tampered total sent in the POST" do
    product = products(:cooking_class)

    post orders_path, params: {
      product_id: product.id, quantity: 2,
      guest_first_name: "Mario", guest_last_name: "Rossi", guest_email: "mario@example.com",
      total_amount: "1", unit_price: "1" # not even a permitted parameter
    }

    order = Order.last
    assert_equal 35.00, order.unit_price.to_f
    assert_equal 70.00, order.total_amount.to_f
  end

  test "a non-purchasable product cannot be checked out" do
    product = products(:not_yet_on_sale)

    assert_no_difference "Order.count" do
      post orders_path, params: {
        product_id: product.id, guest_first_name: "Mario", guest_last_name: "Rossi",
        guest_email: "mario@example.com"
      }
    end

    assert_redirected_to product_path(product)
  end

  test "new redirects away for a non-purchasable product" do
    product = products(:not_yet_on_sale)
    get new_order_path(product_id: product.id)
    assert_redirected_to product_path(product)
  end
end
