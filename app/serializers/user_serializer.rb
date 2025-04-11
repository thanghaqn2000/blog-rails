class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :email, :phone_number, :is_admin, :require_phone_number

  def is_admin
    object.admin?
  end

  def require_phone_number
    object.phone_number.blank?
  end
end
