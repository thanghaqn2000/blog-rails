Rails.application.config.session_store :cookie_store,
  key: '_blog_session',
  path: '/',                         # Áp dụng toàn bộ domain
  secure: Rails.env.production?,     # Bắt buộc HTTPS trong production
  httponly: true,                    # Không cho JS truy cập
  same_site: :lax                    # Cho phép hoạt động khi dùng chung domain FE-BE
