class UserSerializer < ActiveModel::Serializer
  attributes :user_present, :is_superuser, :email
  has_many :memberships

  def user_present
    true if object.present?
  end

  def is_superuser
    true if object.superuser
  end
end
