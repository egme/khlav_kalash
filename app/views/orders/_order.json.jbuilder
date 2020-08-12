json.extract!(
  order,
  :id, :number, :permalink,
  :amount_cents,
  :email_address,
  :first_name, :last_name,
  :country,
  :created_at, :updated_at
)

json.url order_url(order, format: :json)
