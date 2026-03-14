class Api::V1::FeedbacksController < ApplicationController
  def presign
    result = s3_storage_service.generate_presigned_put_url(
      filename: params[:filename],
      content_type: params[:content_type]
    )
    render json: result
  end

  def create
    attrs = feedback_params.to_h
    if (tmp_key = attrs[:image_key]).present?
      promoted = s3_storage_service.promote_tmp_object(tmp_key)
      attrs[:image_key] = promoted[:key]
      attrs[:image_url] = promoted[:url]
    end
    feedback = @current_user.feedbacks.build(attrs)
    if feedback.save
      response_api({ feedback: FeedbackSerializer.new(feedback) }, :created)
    else
      response_api({ errors: feedback.errors.messages }, :bad_request)
    end
  end

  private

  def feedback_params
    params.require(:feedback).permit(:title, :content, :page_issue, :phone_number, :image_key)
  end

  def s3_storage_service
    @s3_storage_service ||= S3StorageService.new
  end
end
