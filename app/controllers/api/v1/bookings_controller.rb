module Api
  module V1
    class BookingsController < ApplicationController
      before_action :set_business, only: [ :index, :create ]
      before_action :set_booking, only: [ :show, :confirm, :cancel, :complete, :no_show ]

      before_action :authenticate_user!, only: [ :index, :show, :confirm, :cancel, :complete, :no_show ]
      before_action :authorize_business_owner_for_index!, only: [ :index ]
      before_action :authorize_booking_owner!, only: [ :show, :confirm, :cancel, :complete, :no_show ]

      # OWNER ONLY
      def index
        bookings = @business
          .bookings
          .includes(:bookable_service)
          .order(start_at: :desc)

        bookings = apply_filters(bookings)

        render_success(
          data: CollectionPresenter.new(
            bookings,
            BookingPresenter
          ).as_json
        )
      end

      # OWNER ONLY
      def show
        render_success(
          data: BookingPresenter.new(@booking).as_json
        )
      end

      # PUBLIC
      def create
        result = CreateBookingService.call(
          business_id: @business.id,
          bookable_service_id: booking_params[:bookable_service_id],
          customer_name: booking_params[:customer_name],
          customer_phone: booking_params[:customer_phone],
          customer_email: booking_params[:customer_email],
          start_at: booking_params[:start_at],
          notes: booking_params[:notes]
        )

        if result.success?
          render_success(
            data: BookingPresenter.new(result.booking).as_json,
            message: "Booking created successfully",
            status: :created
          )
        else
          render_error(
            message: "Booking could not be created",
            errors: result.errors
          )
        end
      end

      # OWNER ONLY
      def confirm
        update_booking_status(:confirm, "Booking confirmed successfully")
      end

      # OWNER ONLY
      def cancel
        update_booking_status(:cancel, "Booking cancelled successfully")
      end

      # OWNER ONLY
      def complete
        update_booking_status(:complete, "Booking completed successfully")
      end

      # OWNER ONLY
      def no_show
        update_booking_status(:mark_as_no_show, "Booking marked as no-show successfully")
      end

      private

      def set_business
        @business = Business.find(params[:business_id])
      end

      def set_booking
        @booking = Booking.find(params[:id])
      end

      def authorize_business_owner_for_index!
        ensure_business_owner!(@business)
      end

      def authorize_booking_owner!
        ensure_business_owner!(@booking.business)
      end

      def booking_params
        params.require(:booking).permit(
          :bookable_service_id,
          :customer_name,
          :customer_phone,
          :customer_email,
          :start_at,
          :notes
        )
      end

      def update_booking_status(action, success_message)
        result = BookingStatusService.call(
          booking: @booking,
          action: action
        )

        if result.success?
          render_success(
            data: BookingPresenter.new(result.booking).as_json,
            message: success_message
          )
        else
          render_error(
            message: "Booking status could not be updated",
            errors: result.errors
          )
        end
      end

      def apply_filters(bookings)
        bookings = bookings.where(status: params[:status]) if params[:status].present?
        bookings = bookings.where(bookable_service_id: params[:bookable_service_id]) if params[:bookable_service_id].present?
        bookings = bookings.where(customer_phone: params[:customer_phone]) if params[:customer_phone].present?
        bookings = bookings.for_date(Date.parse(params[:date])) if params[:date].present?
        bookings = bookings.upcoming if truthy_param?(params[:upcoming])
        bookings = bookings.past if truthy_param?(params[:past])

        bookings
      rescue ArgumentError
        bookings.none
      end

      def truthy_param?(value)
        ActiveModel::Type::Boolean.new.cast(value)
      end
    end
  end
end
