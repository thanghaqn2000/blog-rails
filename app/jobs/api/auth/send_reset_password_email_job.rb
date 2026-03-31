require "net/http"
require "json"
require "uri"
require "cgi"
require "digest"

class Api::Auth::SendResetPasswordEmailJob < ApplicationJob
  queue_as :email
  sidekiq_options retry: 5

  FROM_NAME = "Orca Viet Nam Support".freeze
  FROM_EMAIL = ENV["NOREPLY_EMAIL"].freeze || "no-reply@orcavietnam.com"
  LOGO_URL = "https://orcavietnam.com/logo-orca.png".freeze

  def perform(user_id, raw_token)
    user = User.find_by(id: user_id)
    return if user.blank?

    token_digest = Digest::SHA256.hexdigest(raw_token)
    return unless user.reset_password_token == token_digest
    return if user.reset_password_expires.blank? || user.reset_password_expires < Time.current

    # Dùng đúng origin FE theo môi trường (local/dev/prod) để tránh conflict.
    # Ví dụ trong `.env`: FRONTEND_URL=http://localhost:8080
reset_base = ENV["FRONTEND_URL"].presence || "https://orcavietnam.com"
    reset_base = reset_base.to_s.chomp("/")
    reset_url = "#{reset_base}/reset-password?token=#{CGI.escape(raw_token)}"

    # --- CẬP NHẬT HTML ---
    # Thêm thông tin công ty vào footer để tăng tỷ lệ Text, giúp vượt bộ lọc Image-only
    html = <<~HTML
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Đặt lại mật khẩu Orca</title>
          <style>
            .email-wrapper { font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; background-color: #f4f7f9; padding: 40px 20px; }
            .content-card { max-width: 500px; margin: 0 auto; background: #ffffff; border-radius: 8px; overflow: hidden; box-shadow: 0 4px 10px rgba(0,0,0,0.05); }
            .header { background: #0047BB; padding: 25px; text-align: center; }
            .body { padding: 40px 30px; color: #333333; line-height: 1.6; }
            .btn-wrapper { text-align: center; margin: 30px 0; }
            .button { background-color: #0047BB; color: #ffffff !important; padding: 14px 28px; text-decoration: none; border-radius: 5px; font-weight: bold; display: inline-block; font-size: 16px; }
            .footer { text-align: center; padding: 20px; color: #888888; font-size: 12px; line-height: 1.5; }
            .warning { border-top: 1px solid #eeeeee; padding-top: 20px; margin-top: 20px; font-size: 13px; color: #777777; }
          </style>
        </head>
        <body>
          <div class="email-wrapper">
            <div class="content-card">
              <div class="header">
                <img src="#{LOGO_URL}" alt="Orca Viet Nam Logo" style="max-height: 50px; width: auto; border: 0;">
              </div>
              <div class="body">
                <p style="font-size: 18px; font-weight: bold; margin-bottom: 20px;">Xin chào,</p>
                <p>Chúng tôi đã nhận được yêu cầu thiết lập lại mật khẩu cho tài khoản Orca của bạn. Vui lòng nhấn vào nút bên dưới để tiến hành thay đổi:</p>
                
                <div class="btn-wrapper">
                  <a href="#{reset_url}" class="button">Đặt lại mật khẩu ngay</a>
                </div>

                <p><strong>Lưu ý:</strong> Liên kết này sẽ hết hạn sau 20 phút vì lý do bảo mật. Nếu link không hoạt động, bạn có thể copy địa chỉ sau vào trình duyệt: #{reset_url}</p>
                
                <div class="warning">
                  Nếu bạn không thực hiện yêu cầu này, hãy bỏ qua email này. Tài khoản của bạn vẫn được bảo vệ an toàn.
                </div>
              </div>
            </div>
            <div class="footer">
              <strong>Orca Viet Nam - Hệ thống phân tích tài chính thông minh</strong><br>
              Địa chỉ: Đà Nẵng, Việt Nam.<br>
              © 2026 Orca Viet Nam. Mọi quyền được bảo lưu.<br>
              Bạn nhận được email này vì đã đăng ký tài khoản trên hệ thống Orca.
            </div>
          </div>
        </body>
      </html>
    HTML

    # --- CẬP NHẬT TEXT (Phải tương đồng với HTML để fix MPART_ALT_DIFF) ---
    text = <<~TEXT
      Xin chào,

      Chúng tôi đã nhận được yêu cầu thiết lập lại mật khẩu cho tài khoản Orca của bạn. 
      Vui lòng truy cập đường dẫn sau để tiến hành thay đổi:
      
      #{reset_url}

      Lưu ý: Liên kết này sẽ hết hạn sau 20 phút vì lý do bảo mật.
      Nếu bạn không thực hiện yêu cầu này, hãy bỏ qua email này. Tài khoản của bạn vẫn được bảo vệ an toàn.

      Trân trọng,
      Orca Viet Nam Support.
      © 2026 Orca Viet Nam.
    TEXT

    subject = "Đặt lại mật khẩu tài khoản Orca" # Thêm chữ "tài khoản Orca" để tiêu đề chuyên nghiệp hơn
    send_email_resend(to: user.email, subject: subject, html: html, text: text)
  end

  private

  def send_email_resend(to:, subject:, html:, text:)
    resend_key = ENV["RESEND_KEY"]
    raise "Missing RESEND_KEY" if resend_key.blank?

    uri = URI("https://api.resend.com/emails")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 20

    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{resend_key}"
    request["Content-Type"] = "application/json"

    payload = {
      from: "#{FROM_NAME} <#{FROM_EMAIL}>",
      to: [to],
      subject: subject,
      html: html,
      text: text
    }

    request.body = payload.to_json
    response = http.request(request)

    return if response.is_a?(Net::HTTPSuccess)

    raise "Resend error: HTTP #{response.code} - #{response.body}"
  end
end

