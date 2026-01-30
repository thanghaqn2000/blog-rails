class Api::V1::UserQuotasController < ApplicationController
  include QuotaChecker

  # GET /api/v1/quota
  def show
    quota = @current_user.user_quota
    
    render json: quota, serializer: UserQuotaSerializer
  end
end
