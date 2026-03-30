class Api::V1::Track::ViewsController < Api::V1::BaseController
  def create
    page_type = params.require(:page_type)
    DailyStat.bump_page_view!(page_type)
    head :no_content
  rescue ActionController::ParameterMissing
    raise Api::ParamInvalid, "page_type là bắt buộc"
  rescue ArgumentError
    render json: { error: "page_type phải là home hoặc top_stocks" }, status: :unprocessable_entity
  rescue ActiveRecord::ActiveRecordError => e
    Rails.logger.error("[Track::Views] #{e.class}: #{e.message}")
    head :internal_server_error
  end
end
