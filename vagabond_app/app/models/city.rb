class City < ApplicationRecord
  has_many :posts, dependent: :destroy

  has_one_attached :image

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  def image_variant(...)
    image.variant(...) if image.attached?
  end
end
