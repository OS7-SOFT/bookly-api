module Api
  module V1
    class BusinessesController < ApplicationController
      before_action :authenticate_user!, only: [ :index, :create, :update ]
      before_action :set_business, only: [ :show, :update ]
      before_action :authorize_business_owner!, only: [ :update ]

      def index
        businesses = current_user.businesses.order(created_at: :desc)

        render_success(
          data: CollectionPresenter.new(
            businesses,
            BusinessPresenter
          ).as_json
        )
      end

      def show
        render_success(
          data: BusinessPresenter.new(@business).as_json
        )
      end

      def create
        business = current_user.businesses.new(business_params)

        if business.save
          render_success(
            data: BusinessPresenter.new(business).as_json,
            message: "Business created successfully",
            status: :created
          )
        else
          render_error(
            message: "Business could not be created",
            errors: business.errors.full_messages
          )
        end
      end

      def update
        if @business.update(business_params)
          render_success(
            data: BusinessPresenter.new(@business).as_json,
            message: "Business updated successfully"
          )
        else
          render_error(
            message: "Business could not be updated",
            errors: @business.errors.full_messages
          )
        end
      end

      private

      def set_business
        @business = Business.find(params[:id])
      end

      def authorize_business_owner!
        ensure_business_owner!(@business)
      end

      def business_params
        params.require(:business).permit(
          :name,
          :description,
          :phone,
          :email,
          :address,
          :is_active
        )
      end
    end
  end
end
