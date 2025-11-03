class DeviceToken < ApplicationRecord
  belongs_to :user

  validates :token, presence: true, length: { maximum: 500 }
  validates :device_id, presence: true, uniqueness: { scope: :user_id }
  validates :platform, presence: true, inclusion: { in: %w[android ios web] }

  scope :active, -> { where(active: true) }
  scope :for_platform, ->(platform) { where(platform: platform) }

  # Tìm hoặc tạo device token
  def self.register_token(user:, token:, device_id:, platform:)
    device_token = find_or_initialize_by(user: user, device_id: device_id)
    
    device_token.assign_attributes(
      token: token,
      platform: platform.downcase,
      active: true
    )
    
    device_token.save!
    device_token
  end

  # Vô hiệu hóa token
  def deactivate!
    update!(active: false)
  end

  # Kích hoạt token
  def activate!
    update!(active: true)
  end
end
