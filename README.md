# nexi-xpay-with-rails

Companion code for the [Nexi XPay with Rails](https://antoninoscaffidi.github.io/series/nexi-xpay-with-rails/) series ([Italiano](https://antoninoscaffidi.github.io/it/series/nexi-xpay-with-rails/)) — a from-scratch, generic guide to integrating Nexi XPay's "Pagamento Semplice" (hosted-page) payment flow into a Ruby on Rails app.

One tag per episode (`episode-1`, `episode-2`, ...) so you can check out the exact code state that matches each post.

## Setup

```bash
bundle install
bin/rails db:prepare
bin/rails db:seed
```

You'll need your own Nexi sandbox credentials — get them from the Nexi backoffice, under **Area test → Pagamento Semplice/OneClick**. This is a *different* alias than your production terminal's activation credentials; using the production alias against the sandbox URL fails with `"Alias non valido per l'operazione richiesta"`.

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

32 tests, no external gems. No sandbox credentials or network access needed — the MAC round-trip tests use your own sandbox `mac_key` to sign fixtures and check the gateway can verify its own signatures.

## Reproducing a real end-to-end payment locally

The test suite proves the logic is correct, but Nexi's servers can't reach `localhost` — verifying the actual webhook (`/nexi/notify`) requires a public tunnel.

1. **Start the app**: `bin/dev` (or `bin/rails server -p 3000`).
2. **Install ngrok**: `brew install --cask ngrok`, then `ngrok config add-authtoken <token>` (free account).
3. **Open a tunnel**: `ngrok http 3000`. Copy the `https://...ngrok-free.app` URL it prints.
4. **Browse from the ngrok URL, not `localhost`** — otherwise the `notify_url` this app generates points somewhere Nexi can never reach. The first visit shows a one-time ngrok interstitial ("Visit Site"); click through once per browser.
5. **Checkout with a Nexi test card**: `4539 9700 0000 0006` (approved) or `4539 9700 0000 0014` (declined, useful for testing the KO path). Any future expiry date, any 3-digit CVV. 3D Secure OTP is always `123456`.
6. **Check the result**: `bin/rails runner 'p Order.last.status; p Order.last.order_payment_notifications.last.outcome'`. If the webhook arrived on its own, the order is already `paid` — no manual step involved.

## Going to production

Not covered by this repo, but worth knowing before you flip the switch:

- Add a `nexi.production` block to credentials, with your real terminal's alias, MAC key, and the production `pay_url` (`https://ecommerce.nexi.it/...`, no `int-` prefix).
- Send a confirmation email from `NexiCallbacksController#notify`, after `mark_paid!` — never from `#return`, which is UX-only and can be skipped entirely if the customer closes their browser.
- An admin view to inspect orders and notifications (read-mostly; a refund action should be explicit, never a generic update on financial fields).
- Consider validating `params[:importo]`/`params[:divisa]` against `order.total_amount`/`order.currency` before calling `mark_paid!`, as defense-in-depth beyond the MAC check.

## Episodes

1. Setting up and initiating a payment
2. Handling the outcome: webhook, MAC verification, and real bugs
3. Testing, local end-to-end verification, and going to production
