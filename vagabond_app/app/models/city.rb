class City < ApplicationRecord
  has_many :posts, dependent: :destroy

  has_one_attached :image

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  def image_variant(...)
    image.variant(...) if image.attached?
  end

  # Fetches and attaches a stock photo for this city by name. Returns true on
  # success. Safe to call when an image is already attached (no-op by default).
  def attach_stock_image!(force: false)
    return false if image.attached? && !force

    result = CityImageLookup.call(name)
    return false unless result

    image.attach(io: result.io, filename: result.filename, content_type: result.content_type)
    true
  end
end
