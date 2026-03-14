class Api::Admin::FeedbacksController < Api::Admin::BaseController
  before_action :set_feedback, only: %i[show update destroy]

  def index
    feedbacks = Feedback.includes(:user)
                       .ransack(title_cont: params[:title], status_eq: params[:status])
                       .result
                       .order(created_at: :desc)

    render_paginated(feedbacks, serializer: FeedbackSerializer)
  end

  def show
    render json: @feedback, serializer: FeedbackSerializer
  end

  def update
    if @feedback.update(update_params)
      render json: @feedback, serializer: FeedbackSerializer
    else
      render json: { errors: @feedback.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @feedback.destroy!
    render json: { message: "Feedback deleted successfully" }
  end

  private

  def set_feedback
    @feedback = Feedback.find(params[:id])
  end

  def update_params
    params.require(:feedback).permit(:status)
  end
end
