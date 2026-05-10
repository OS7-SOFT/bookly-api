class BookableService < ApplicationRecord
  belongs_to :business

  has_many :bookings, dependent: :restrict_with_error

  validates :name, presence: true, length: { maximum: 150 }
  validates :description, length: { maximum: 1_000 }, allow_blank: true

  validates :duration_minutes,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than: 0,
              less_than_or_equal_to: 1_440
            }

  validates :price,
            presence: true,
            numericality: { greater_than_or_equal_to: 0 }

  scope :active, -> { where(is_active: true) }
end
