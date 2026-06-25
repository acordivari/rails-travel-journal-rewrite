class User < ApplicationRecord
  has_secure_password

  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy

  has_one_attached :avatar

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :name, presence: true
  validates :email,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }

  def admin?
    admin
  end
end
