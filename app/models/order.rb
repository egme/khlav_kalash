class Order < ApplicationRecord
  after_initialize :set_price
  after_validation :set_payment_intent_id, if: -> { errors.size.zero? && payment_intent_id.nil? }
  before_create :set_uids

  validates :first_name, :country, :postal_code, :email_address, presence: true
  validates :email_address, email: true, unless: -> { email_address.blank? }

  UNIT_PRICE_CENTS = ENV.fetch("UNIT_PRICE_CENTS", 299).to_i
  CURRENCY = "USD".freeze

  def price
    Money.new(amount_cents, CURRENCY)
  end

  def billing_details_hash
    {
      name: [first_name, last_name].join(" ").strip,
      email: email_address,
      address: {
        city: city,
        country: country,
        line1: street_line_1,
        line2: street_line_2,
        postal_code: postal_code,
        state: region
      }.delete_if { |_k, v| v.empty? }
    }.delete_if { |_k, v| v.empty? }
  end

  def as_json(*)
    hash = super
    hash["created_at"] = created_at.iso8601 if hash.key?("created_at")
    hash["updated_at"] = updated_at.iso8601 if hash.key?("updated_at")
    hash
  end

  private

  def set_price
    self.amount_cents ||= UNIT_PRICE_CENTS
  end

  def set_payment_intent_id
    intent = StripePayments.create_intent(UNIT_PRICE_CENTS, CURRENCY)
    self.payment_intent_id = intent.id
  rescue StripePayments::APIError => e
    errors[:base] << "Unable to prepare payment (#{e.message}). Try again later."
  end

  def set_uids
    self.number = next_number
    self.permalink = new_permalink
  end

  def next_number
    current = self.class.reorder("number desc").first.try(:number) || "000000000000"
    current.next
  end

  def new_permalink
    permalink = SecureRandom.hex(20)
    permalink = SecureRandom.hex(20) while Order.where(permalink: permalink).any?
    permalink
  end
end
