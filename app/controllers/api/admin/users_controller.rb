# frozen_string_literal: true

class Api::Admin::UsersController < Api::Admin::BaseController
  before_action :set_user, only: %i[show update destroy reset_password]

  def index
    users = User.ransack(params[:q]).result.order(created_at: :desc)
    render_paginated(users, serializer: UserSerializer)
  end

  def show
    render json: @user, serializer: UserSerializer
  end

  def create
    user = User.new(user_params)
    if user.save
      response_api({ user: UserSerializer.new(user) }, :created)
    else
      response_api({ errors: user.errors.messages }, :bad_request)
    end
  end

  def update
    attrs = user_params.to_h
    quota_adjustment = attrs.delete(:quota_adjustment) || attrs.delete("quota_adjustment") || params[:quota_adjustment]
    attrs.delete(:user_quota_attributes) if quota_adjustment.present? # dùng điều chỉnh thì bỏ absolute

    if quota_adjustment.present?
      quota = @user.user_quota
      return response_api({ errors: "User chưa có quota" }, :bad_request) unless quota
    end

    User.transaction do
      quota.apply_adjustment!(quota_adjustment) if quota_adjustment.present?
      unless @user.update(attrs)
        raise ActiveRecord::Rollback
      end
    end

    if @user.errors.any?
      response_api({ errors: @user.errors.messages }, :bad_request)
    else
      response_api({ user: UserSerializer.new(@user.reload) }, :ok)
    end
  end

  def destroy
    if @user.id == @current_admin.id
      return response_api({ error: 'Không thể xóa chính mình' }, :unprocessable_entity)
    end
    @user.destroy
    response_api({ message: 'Đã xóa người dùng' }, :ok)
  end

  def reset_password
    @user.update!(password: ENV['DEFAULT_PASSWORD'])
    response_api({ message: 'Đã đặt lại mật khẩu' }, :ok)
  end

  def conversations
    user = User.find_by(id: params[:user_id])
    return response_api({ errors: 'Không tìm thấy người dùng' }, :not_found) unless user

    convos = user.conversations.order(created_at: :desc)
    render_paginated(convos, serializer: ConversationSerializer)
  end

  def messages
    conversation = Conversation.find_by(id: params[:conversation_id])
    return response_api({ errors: 'Không tìm thấy cuộc hội thoại' }, :not_found) unless conversation

    messages = conversation.messages.order(id: :asc)
    cursor = params[:cursor].presence
    messages = messages.where('id > ?', cursor) if cursor.present?
    messages = messages.limit(params[:limit].presence || 20)
    render json: {
      data: ActiveModelSerializers::SerializableResource.new(messages, each_serializer: MessageSerializer).as_json,
      next_cursor: messages.any? ? messages.last.id : nil
    }
  end

  private

  def set_user
    @user = User.find_by(id: params[:id])
    return response_api({ errors: 'Không tìm thấy người dùng' }, :not_found) unless @user
  end

  def user_params
    params.require(:user).permit(
      :name, :email, :phone_number, :role,
      :quota_adjustment,
      user_quota_attributes: [:daily_limit, :used_today]
    )
  end
end
