module Api
  module V1
    class WorkingHoursController < ApplicationController
      before_action :set_business, only: [ :index, :create ]
      before_action :set_working_hour, only: [ :show, :update, :destroy ]

      before_action :authenticate_user!, only: [ :create, :update, :destroy ]
      before_action :authorize_business_owner_for_create!, only: [ :create ]
      before_action :authorize_business_owner!, only: [ :update, :destroy ]

      def index
        working_hours = @business.working_hours.order(:day_of_week)

        render_success(
          data: CollectionPresenter.new(
            working_hours,
            WorkingHourPresenter
          ).as_json
        )
      end

      def show
        render_success(
          data: WorkingHourPresenter.new(@working_hour).as_json
        )
      end

      def create
        working_hour = @business.working_hours.new(working_hour_params)

        if working_hour.save
          render_success(
            data: WorkingHourPresenter.new(working_hour).as_json,
            message: "Working hour created successfully",
            status: :created
          )
        else
          render_error(
            message: "Working hour could not be created",
            errors: working_hour.errors.full_messages
          )
        end
      end

      def update
        if @working_hour.update(working_hour_params)
          render_success(
            data: WorkingHourPresenter.new(@working_hour).as_json,
            message: "Working hour updated successfully"
          )
        else
          render_error(
            message: "Working hour could not be updated",
            errors: @working_hour.errors.full_messages
          )
        end
      end

      def destroy
        @working_hour.destroy!

        render_success(
          message: "Working hour deleted successfully"
        )
      end

      private

      def set_business
        @business = Business.find(params[:business_id])
      end

      def set_working_hour
        @working_hour = WorkingHour.find(params[:id])
      end

      def authorize_business_owner_for_create!
        ensure_business_owner!(@business)
      end

      def authorize_business_owner!
        ensure_business_owner!(@working_hour.business)
      end

      def working_hour_params
        params.require(:working_hour).permit(
          :day_of_week,
          :start_time,
          :end_time,
          :is_closed
        )
      end
    end
  end
end
