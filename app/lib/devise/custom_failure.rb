class Devise::CustomFailure < Devise::FailureApp
  def respond
    if request.controller_class.to_s.start_with? "Api"
      json_error_response
    else
      super
    end
  end

  def json_error_response
    self.status = 401
    self.content_type = "application/json"
    self.response_body = {success: false, errors: "Invalid email or password", status: 401}.to_json
  end
end
