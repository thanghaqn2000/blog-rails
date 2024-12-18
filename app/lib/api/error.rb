# lib/api/errors.rb
module Api
  class Error < StandardError
    attr_reader :message, :status

    def initialize(message, status)
      super(message)
      @message = message
      @status = status
    end

    def to_hash
      { error: @message, status: @status }
    end
  end

  class NotFound < Error
    def initialize(message = 'Not Found')
      super(message, 404)
    end
  end

  class ParamInvalid < Error
    def initialize(message = 'Invalid parameter')
      super(message, 400)
    end
  end

  class InternalError < Error
    def initialize(message = 'Internal Server Error')
      super(message, 500)
    end
  end

  class MethodNotAllowed < Error
    def initialize(message = 'Method Not Allowed')
      super(message, 403)
    end
  end
end
