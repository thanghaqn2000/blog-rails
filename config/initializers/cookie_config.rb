# config/initializers/cookie_config.rb
Rails.application.config.to_prepare do
  # Định nghĩa cấu hình cookie
  COOKIE_OPTIONS = {
    httponly: true, # Ngăn chặn truy cập từ JavaScript
    secure: Rails.env.production?, # Chỉ gửi cookie qua HTTPS trong môi trường production
    same_site: :strict, # Ngăn chặn tấn công CSRF
    expires: 7.days.from_now # Thời gian sống của cookie
  }.freeze
end
