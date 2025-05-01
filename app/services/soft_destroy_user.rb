class SoftDestroyUser
  def initialize user
    @user = user
  end

  def perform
    user.update_attribute :email, "#{user.email}_deleted_#{Time.current.to_i}_#{SecureRandom.hex(4)}"
    user.destroy
  end

  private
  attr_reader :user
end
