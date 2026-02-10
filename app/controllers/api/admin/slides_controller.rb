class Api::Admin::SlidesController < Api::Admin::BaseController
  before_action :set_slide, only: %i[update destroy]

  def reorder
    ids = params[:slide_ids]
    return render json: { errors: "slide_ids must be an array" }, status: :bad_request unless ids.is_a?(Array)

    Slide.transaction do
      ids.each_with_index do |id, index|
        Slide.where(id: id).update_all(position: index)
      end
    end

    render json: { message: "Slides reordered successfully" }
  end

  def index
    slides = Slide.order(position: :asc, created_at: :asc)
    render json: slides, each_serializer: SlideSerializer
  end

  def create
    attrs = slide_params.to_h

    if (tmp_key = attrs.delete(:image_key)).present?
      promoted = s3_storage_service.promote_tmp_object(tmp_key)
      attrs[:image_url] = promoted[:url]
    end

    # mặc định thêm slide mới ở cuối danh sách
    max_position = Slide.maximum(:position) || 0
    slide = Slide.new(attrs.merge(position: max_position + 1))

    if slide.save
      render json: { message: "Slide created successfully", slide: SlideSerializer.new(slide) }, status: :created
    else
      render json: { errors: slide.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    attrs = slide_params.to_h

    if (tmp_key = attrs.delete(:image_key)).present?
      promoted = s3_storage_service.promote_tmp_object(tmp_key)
      attrs[:image_url] = promoted[:url]
    end

    if @slide.update(attrs)
      render json: @slide, serializer: SlideSerializer
    else
      render json: { errors: @slide.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    if @slide.destroy
      render json: { message: "Delete slide ok!" }
    else
      render json: { errors: @slide.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_slide
    @slide = Slide.find_by(id: params[:id])
    return response_api({ errors: "Slide not found" }, :not_found) unless @slide
  end

  def slide_params
    # Không cho phép client set trực tiếp image_url,
    # luôn đi qua luồng S3 promote_tmp_object với image_key
    params.require(:slide).permit(:heading, :description, :image_key)
  end

  def s3_storage_service
    @s3_storage_service ||= S3StorageService.new
  end
end

