# nexi-xpay-with-rails

Companion code for the [Nexi XPay with Rails](https://antoninoscaffidi.github.io/series/nexi-xpay-with-rails/) series ([Italiano](https://antoninoscaffidi.github.io/it/series/nexi-xpay-with-rails/)) — a from-scratch, generic guide to integrating Nexi XPay's "Pagamento Semplice" (hosted-page) payment flow into a Ruby on Rails app.

One tag per episode (`episode-1`, `episode-2`, ...) so you can check out the exact code state that matches each post.

## Setup

```bash
bundle install
bin/rails db:prepare
```

You'll need your own Nexi sandbox credentials — see the episode 1 post for where to get them from the Nexi backoffice. Add them with:

```bash
bin/rails credentials:edit
```

```yaml
nexi:
  sandbox:
    alias: YOUR_SANDBOX_ALIAS
    mac_key: your_sandbox_mac_key
    pay_url: https://int-ecommerce.nexi.it/ecomm/ecomm/DispatcherServlet
```

## Running the tests

```bash
bin/rails test
```

## Episodes

1. Setting up and initiating a payment
