class RefreshToken < ApplicationRecord
  MAX_ACTIVE_SESSIONS = 3

  belongs_to :user

  validates :token_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :active, -> { where(revoked_at: nil).where('expires_at > ?', Time.current) }

  def revoke!
    update!(revoked_at: Time.current)
  end

  def active?
    revoked_at.nil? && expires_at > Time.current
  end

  # Hash raw token bằng SHA256
  def self.digest(raw_token)
    Digest::SHA256.hexdigest(raw_token)
  end

  # Tìm active token bằng raw token
  def self.find_active_by_raw_token(raw_token)
    active.find_by(token_digest: digest(raw_token))
  end

  # Enforce max sessions: revoke oldest nếu đã đủ 3
  # Trả về true nếu đã revoke (vượt giới hạn), false nếu không
  # Dùng FOR UPDATE để lock rows, tránh race condition khi concurrent login
  def self.enforce_max_sessions!(user)
    active_tokens = user.refresh_tokens.lock.active.order(created_at: :asc)
    return false if active_tokens.count < MAX_ACTIVE_SESSIONS

    tokens_to_revoke = active_tokens.limit(active_tokens.count - MAX_ACTIVE_SESSIONS + 1)
    tokens_to_revoke.update_all(revoked_at: Time.current)
    true
  end
end
