class Api::V1::BaseController < ApplicationController
  skip_before_action :authorize_request!
end
