class User < ApplicationRecord
  has_secure_password
  acts_as_paranoid

  validates :email, presence: { message: "Email là bắt buộc" },
            uniqueness: { message: "Email này đã được sử dụng" },
            format: { with: URI::MailTo::EMAIL_REGEXP, message: "Invalid email format" }
  validates :password, presence: { message: "Mật khẩu là bắt buộc" },
            length: { minimum: 6, message: "Mật khẩu phải ít nhất 6 kí tự" }
  validates :phone_number, presence: true, format: { with: /\A\d{10}\z/, message: "Không đúng định dạng số điện thoại" },
            uniqueness: { message: "Số điện thoại này đã được sử dụng" }
  validates :name, presence: { message: "Tên là bắt buộc" }
end
