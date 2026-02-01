class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :email, :phone_number, :is_admin, :require_phone_number, :avatar_url, :is_vip

  def is_admin
    object.admin?
  end

  def is_vip
    object.vip?
  end

  def require_phone_number
    object.phone_number.blank?
  end
end
