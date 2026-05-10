class BusinessPresenter
  def initialize(business)
    @business = business
  end

  def as_json(*)
    {
      id: @business.id,
      user_id: @business.user_id,
      name: @business.name,
      description: @business.description,
      phone: @business.phone,
      email: @business.email,
      address: @business.address,
      is_active: @business.is_active,
      created_at: @business.created_at,
      updated_at: @business.updated_at
    }
  end
end
