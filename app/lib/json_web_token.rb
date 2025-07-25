class JsonWebToken
  HMAC_SECRET = Rails.application.credentials.secret_key_base

  class << self
    def encode payload, exp
      payload[:exp] = exp.to_i
      JWT.encode payload, HMAC_SECRET
    end

    def decode token
      data = JWT.decode(token, HMAC_SECRET)[0]
      HashWithIndifferentAccess.new data
    end
  end
end
