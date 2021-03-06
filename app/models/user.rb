class User < ApplicationRecord
  attr_accessor :remember_token, :activation_token, :reset_token
  has_secure_password :password
  has_one :cart, dependent: :destroy
  has_many :orders, dependent: :destroy
  before_create :create_activation_digest
  before_save :email_downcase
  validate :validate_password
  validates :name, presence: true, length: { minimum: 6 }
  validates :password_digest, presence: true, length: { minimum: 6 }, allow_nil: true
  validates :email, presence: true, uniqueness: true,
                    length: { minimum: 10 }, format: { with: URI::MailTo::EMAIL_REGEXP }

  def create_reset_digest
    self.reset_token = User.new_token
    update_attribute(:reset_digest, User.digest(reset_token))
    update_attribute(:reset_sent_at, Time.zone.now)
  end

  def send_password_reset_email
    UserMailer.password_reset(self).deliver_now
  end

  def password_reset_expired?
    reset_sent_at < 2.hour.ago
  end

  def self.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
               BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end

  def self.new_token
    SecureRandom.urlsafe_base64
  end

  def remember
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(remember_token))
  end

  def forget
    update_attribute(:remember_digest, nil )
  end

  def authenticated?(attribute, token)
    digest = send("#{attribute}_digest")
    return false if digest.nil?
    BCrypt::Password::new(digest).is_password?(token)
  end

  def activate
    update_attribute(:activated, true)
    update_attribute(:activated_at, Time.zone.now)
  end

  def send_activation_mail
    UserMailer.account_activation(self).deliver_now
  end

  private

    def create_activation_digest
      self.activation_token = User.new_token
      self.activation_digest = User.digest(activation_token)
    end

    def email_downcase
      self.email = email.downcase
    end

    def validate_password
      errors.add(:password,"too short") if password.length < 7
      errors.add(:password,"can't be empty") if password.empty?
    end
end
