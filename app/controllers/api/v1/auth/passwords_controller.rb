require "digest"
require "securerandom"

class Api::V1::Auth::PasswordsController < Api::V1::BaseController
  # POST /api/v1/auth/forgot-password
  def forgot_password
    email = params[:email].to_s.strip.downcase
    raise Api::ParamInvalid, "email là bắt buộc" if email.blank?

    # Rate limit theo email: 1 request / 3 phút / email
    unless Api::Auth::PasswordResetRateLimiter.allowed?(email)
      return render json: { message: reset_password_generic_message }, status: :ok
    end

    user = User.find_by(email: email)
    return render json: { message: reset_password_generic_message }, status: :ok unless user

    raw_token = SecureRandom.hex(20) # 20 bytes -> hex string 40 chars
    token_digest = Digest::SHA256.hexdigest(raw_token)
    expires_at = 20.minutes.from_now

    # Dùng update_columns để tránh trigger các validations không liên quan (user có thể được tạo từ social login
    # với `save!(validate: false)` nên một số field bắt buộc có thể trống).
    user.update_columns(
      reset_password_token: token_digest,
      reset_password_sent_at: Time.current,
      reset_password_expires: expires_at
    )

    Api::Auth::SendResetPasswordEmailJob.perform_later(user.id, raw_token)
    render json: { message: reset_password_generic_message }, status: :ok
  rescue Api::Error => e
    raise e
  rescue ActiveRecord::ActiveRecordError => e
    Rails.logger.error("[ForgotPassword] #{e.class}: #{e.message}")
    # Vẫn trả 200 để không leak thông tin & không làm UX xấu.
    render json: { message: reset_password_generic_message }, status: :ok
  end

  # POST /api/v1/auth/reset-password
  def reset_password
    raw_token = params[:token].to_s
    new_password = params[:new_password].to_s

    raise Api::ParamInvalid, "token là bắt buộc" if raw_token.blank?
    raise Api::ParamInvalid, "new_password là bắt buộc" if new_password.blank?
    raise Api::ParamInvalid, "Mật khẩu phải ít nhất 6 kí tự" if new_password.length < 6

    token_digest = Digest::SHA256.hexdigest(raw_token)
    user = User.find_by(reset_password_token: token_digest)

    raise Api::ParamInvalid, "Token không hợp lệ hoặc đã hết hạn" if user.blank?
    raise Api::ParamInvalid, "Token không hợp lệ hoặc đã hết hạn" if user.reset_password_expires.blank? || user.reset_password_expires < Time.current

    User.transaction do
      user.password = new_password
      user.reset_password_token = nil
      user.reset_password_sent_at = nil
      user.reset_password_expires = nil
      # Bỏ validations để không vướng field khác (vd: phone_number có thể nil với user social login).
      user.save!(validate: false)
    end

    render json: { message: "Đặt lại mật khẩu thành công" }, status: :ok
  rescue Api::Error => e
    raise e
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: user_errors(e) }, status: :bad_request
  end

  private
    def reset_password_generic_message
      "Nếu email tồn tại trong hệ thống, bạn sẽ nhận được email hướng dẫn đặt lại mật khẩu."
    end

    def user_errors(active_record_error)
      return ["Mật khẩu không hợp lệ"] if active_record_error.record.blank?
      active_record_error.record.errors.full_messages
    end
end

