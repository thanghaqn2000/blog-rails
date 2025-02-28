class FilterSensitiveData
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, response = @app.call(env)

    if response.body.present?
      begin
        # Parse the response body as JSON
        data = JSON.parse(response.body)

        # Check if both access_token and refresh_token exist in the response
        if data.dig('token_info', 'access_token') && data.dig('token_info', 'refresh_token')
          # Encrypt access_token and refresh_token
          data['token_info']['access_token'] = mask_token(data['token_info']['access_token'])
          data['token_info']['refresh_token'] = mask_token(data['token_info']['refresh_token'])

          # Update the response body with the modified data
          new_response = [data.to_json] # Tạo response mới
          headers["Content-Length"] = new_response.first.bytesize.to_s
          return [status, headers, new_response]
        end
      rescue JSON::ParserError
        # If the response is not JSON, do nothing
      end
    end

    [status, headers, response]
  end

  private

  # Mask a token by keeping the first 3 and last 3 characters, and

  def mask_token(token)
    token[0..2] + '***' + token[-3..-1] # Che một phần token
  end
end
