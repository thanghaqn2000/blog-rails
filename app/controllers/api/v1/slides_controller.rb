class Api::V1::SlidesController < Api::V1::BaseController
  def index
    slides = Slide.order(position: :asc, created_at: :asc)
    render json: slides, each_serializer: SlideSerializer
  end
end

