class JsonWebToken
  HMAC_SECRET = ENV.fetch("JWT_SECRET")

  class << self
    def encode(payload, exp)
      payload[:exp] = exp.to_i
      JWT.encode(payload, HMAC_SECRET, "HS256")
    end

    def decode(token)
      data = JWT.decode(token, HMAC_SECRET, true, algorithm: "HS256")[0]
      HashWithIndifferentAccess.new(data)
    end
  end
end
