class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable, authentication_keys: [:phone_number]

  enum role: { user: 0, admin: 1 }

  has_many :posts
  has_many :notifications
  has_many :device_tokens, dependent: :destroy

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if phone_number = conditions.delete(:phone_number)
      where(conditions).where(['phone_number = :value', { value: phone_number }]).first
    else
      where(conditions).first
    end
  end

  acts_as_paranoid

  validates :email, presence: { message: "Email là bắt buộc" },
            uniqueness: { message: "Email này đã được sử dụng" },
            format: { with: URI::MailTo::EMAIL_REGEXP, message: "Invalid email format" }
            validates :password, presence: { message: "Mật khẩu là bắt buộc" },
            length: { minimum: 6, message: "Mật khẩu phải ít nhất 6 kí tự" },
            if: -> { new_record? || password.present? }
  validates :phone_number, presence: true, format: { with: /\A\d{10}\z/, message: "Không đúng định dạng số điện thoại" },
            uniqueness: { message: "Số điện thoại này đã được sử dụng" }
  validates :name, presence: { message: "Tên là bắt buộc" }

  def email_required?
    false
  end

  def email_changed?
    false
  end

  def will_save_change_to_email?
    false
  end

  def admin?
    role == "admin"
  end

  # Lấy tất cả active device tokens
  def active_device_tokens
    device_tokens.active
  end

  # Lấy tất cả active FCM tokens
  def active_fcm_tokens
    active_device_tokens.pluck(:token)
  end

  # Đăng ký device token mới
  def register_device_token(token:, device_id:, platform:)
    DeviceToken.register_token(
      user: self,
      token: token,
      device_id: device_id,
      platform: platform
    )
  end
end
