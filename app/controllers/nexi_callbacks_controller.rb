class NexiCallbacksController < ActionController::Base
  skip_before_action :verify_authenticity_token, only: [ :notify ]

  # TODO episode 2: verify the MAC, look up the order, log the notification,
  # and mark the order paid. For now this only needs to exist so Nexi has an
  # HTTPS endpoint to call and our redirect/notify URLs resolve to something.
  def notify
    head :ok
  end

  def return
    redirect_to root_path
  end
end
