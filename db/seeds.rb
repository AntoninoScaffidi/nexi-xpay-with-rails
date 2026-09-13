# A single purchasable product, priced low on purpose to stay comfortably
# inside the sandbox environment's limits while testing a real payment.
Product.find_or_create_by!(name: "Sample experience") do |product|
  product.price = 12.00
  product.purchasable = true
end
