class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :email, :phone_number, :is_admin

  def is_admin
    object.admin?
  end
end
