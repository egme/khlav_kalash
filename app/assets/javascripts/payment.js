document.addEventListener("DOMContentLoaded", function () {
  function showError(message) {
    document.getElementById("card-errors").textContent = message;
  }

  var style = {
    base: {
      color: "#32325d",
    }
  };

  var stripe = Stripe(window.PAYMENT_CONFIG.STRIPE_PUBLIC_KEY);
  var elements = stripe.elements();
  var card = elements.create("card", { style: style });
  card.mount("#card-element");
  card.on("change", function(event) {
    if (event.error) {
      showError(event.error.message);
    } else {
      showError("");
    }
  });

  var button = document.getElementById("pay");
  button.addEventListener("click", function (ev) {
    ev.preventDefault();

    button.disabled = true;

    stripe.confirmCardPayment(
      window.PAYMENT_CONFIG.INTENT_CLIENT_SECRET,
      {
        payment_method: {
          card: card,
          billing_details: window.PAYMENT_CONFIG.BILLING_DETAILS_HASH
        },
        setup_future_usage: "on_session"
      }
    )
    .then(function(result) {
      if (result.error) {
        showError(result.error.message);
        button.disabled = false;
      } else if (result.paymentIntent.status === "succeeded") {
          window.location.assign("/order/" + window.PAYMENT_CONFIG.PERMALINK);
      } else {
        // TODO: what else?
        button.disabled = false;
      }
    })
    .catch(function(error) {
      showError(error.message);
    });
  });
});
