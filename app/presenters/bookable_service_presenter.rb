class BookableServicePresenter
  def initialize(bookable_service)
    @bookable_service = bookable_service
  end

  def as_json(*)
    {
      id: @bookable_service.id,
      business_id: @bookable_service.business_id,
      name: @bookable_service.name,
      description: @bookable_service.description,
      duration_minutes: @bookable_service.duration_minutes,
      price: @bookable_service.price.to_s,
      is_active: @bookable_service.is_active,
      created_at: @bookable_service.created_at,
      updated_at: @bookable_service.updated_at
    }
  end
end
