class Post < ApplicationRecord
  belongs_to :user
  belongs_to :city

  has_many :comments, dependent: :destroy

  has_one_attached :photo

  validates :title, presence: true, length: { maximum: 200 }
  validates :body, presence: true

  scope :recent, -> { order(created_at: :desc) }

  def edited?
    updated_at - created_at > 1.second
  end

  def excerpt(length = 140)
    body.truncate(length)
  end
end
