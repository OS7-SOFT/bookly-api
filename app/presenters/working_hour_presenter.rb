class WorkingHourPresenter
  def initialize(working_hour)
    @working_hour = working_hour
  end

  def as_json(*)
    {
      id: @working_hour.id,
      business_id: @working_hour.business_id,
      day_of_week: @working_hour.day_of_week,
      start_time: formatted_time(@working_hour.start_time),
      end_time: formatted_time(@working_hour.end_time),
      is_closed: @working_hour.is_closed,
      created_at: @working_hour.created_at,
      updated_at: @working_hour.updated_at
    }
  end

  private

  def formatted_time(value)
    return nil if value.blank?

    value.strftime("%H:%M")
  end
end
