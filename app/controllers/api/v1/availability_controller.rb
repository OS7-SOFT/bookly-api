module Api
  module V1
    class AvailabilityController < ApplicationController
      def show
        result = AvailabilityService.call(
          business_id: params[:business_id],
          bookable_service_id: params[:bookable_service_id],
          date: params[:date]
        )

        if result.success?
          render_success(data: result.data)
        else
          render_error(
            message: "Availability could not be loaded",
            errors: result.errors
          )
        end
      end
    end
  end
end
