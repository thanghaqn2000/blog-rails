class Api::Admin::NotificationsController < Api::Admin::BaseController
  before_action :set_notification, only: [:show, :update, :destroy, :send_notification]

  def index
    notifications = Notification.includes(:user).page(params[:page]).per(params[:per_page] || 10)

    render_paginated(notifications, serializer: NotificationSerializer)
  end

  def create
    @notification = @current_admin.notifications.build(notification_params)

    if @notification.save
      case @notification.type
      when 'sent_now'
        @notification.send_now!
      when 'scheduled'
        @notification.schedule_notification if @notification.scheduled_at.present?
      end
      render json: { message: "Notification created successfully" }, status: :created
    else
      render json: { errors: @notification.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @notification.update(notification_params)
      render json: { message: "Notification created successfully" }, status: :ok
    else
      render json: {
        errors: @notification.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def destroy
    if @notification.destroy
      render json: {
        message: 'Notification đã được xóa thành công'
      }, status: :ok
    else
      render json: {
        message: 'Không thể xóa notification',
        errors: @notification.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # POST /api/admin/notifications/:id/send
  def send_notification
    case params[:send_type]
    when 'now'
      @notification.send_now!
      render json: { message: 'Notification đã được gửi đến tất cả users' }, status: :ok
    when 'topic'
      topic = params[:topic]
      return render json: { message: 'Topic là bắt buộc' }, status: :bad_request if topic.blank?
      
      result = @notification.send_to_topic!(topic)
      if result[:success]
        render json: { message: "Notification đã được gửi đến topic: #{topic}" }, status: :ok
      else
        render json: { message: "Lỗi gửi đến topic: #{result[:error]}" }, status: :unprocessable_entity
      end
    when 'devices'
      device_tokens = params[:device_tokens]
      return render json: { message: 'Device tokens là bắt buộc' }, status: :bad_request if device_tokens.blank?
      
      result = @notification.send_to_devices!(device_tokens)
      render json: { 
        message: result[:message],
        details: {
          total: result[:total_tokens],
          success: result[:success_count],
          failed: result[:failed_count]
        }
      }, status: :ok
    else
      render json: { message: 'Send type không hợp lệ. Sử dụng: now, topic, hoặc devices' }, status: :bad_request
    end
  rescue => e
    render json: { 
      message: 'Có lỗi xảy ra khi gửi notification',
      error: e.message 
    }, status: :internal_server_error
  end

  private

  def set_notification
    @notification = Notification.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      message: 'Không tìm thấy notification'
    }, status: :not_found
  end

  def notification_params
    params.require(:notification).permit(:title, :content, :type, :status, :scheduled_at, :sent_at)
  end
end
