class UserPresenter
  def initialize(user)
    @user = user
  end

  def as_json(*)
    {
      id: @user.id,
      full_name: @user.full_name,
      email: @user.email,
      created_at: @user.created_at,
      updated_at: @user.updated_at
    }
  end
end
