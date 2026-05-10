class Business < ApplicationRecord
  belongs_to :user

  has_many :bookable_services, dependent: :destroy
  has_many :working_hours, dependent: :destroy
  has_many :bookings, dependent: :destroy

  normalizes :email, with: ->(email) { email&.strip&.downcase }
  normalizes :phone, with: ->(phone) { phone&.strip }

  validates :name, presence: true, length: { maximum: 150 }
  validates :description, length: { maximum: 1_000 }, allow_blank: true
  validates :phone, length: { maximum: 30 }, allow_blank: true
  validates :email,
            format: { with: URI::MailTo::EMAIL_REGEXP },
            allow_blank: true
  validates :address, length: { maximum: 255 }, allow_blank: true

  scope :active, -> { where(is_active: true) }
end
