class Api::V1::BaseController < ApplicationController
  skip_before_action :authorize_request!

  def current_user
    refresh_token = cookies.signed[:refresh_token]
    return if refresh_token.blank?

    User.find_by(refresh_token: refresh_token)
  end
end
