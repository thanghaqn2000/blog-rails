class UserQuotaSerializer < ActiveModel::Serializer
  attributes :total_limit, :used, :remaining

  def total_limit
    object.daily_limit
  end

  def used
    object.used_today
  end

  def remaining
    object.remaining
  end
end
