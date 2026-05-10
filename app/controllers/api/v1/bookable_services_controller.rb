module Api
  module V1
    class BookableServicesController < ApplicationController
      before_action :set_business, only: [ :index, :create ]
      before_action :set_bookable_service, only: [ :show, :update, :destroy ]

      # 🔐 فقط للعمليات الإدارية
      before_action :authenticate_user!, only: [ :create, :update, :destroy ]
      before_action :authorize_business_owner_for_create!, only: [ :create ]
      before_action :authorize_business_owner!, only: [ :update, :destroy ]

      # PUBLIC
      def index
        bookable_services = @business
          .bookable_services
          .where(is_active: true)
          .order(created_at: :desc)

        render_success(
          data: CollectionPresenter.new(
            bookable_services,
            BookableServicePresenter
          ).as_json
        )
      end

      # PUBLIC
      def show
        render_success(
          data: BookableServicePresenter.new(@bookable_service).as_json
        )
      end

      # OWNER ONLY
      def create
        bookable_service = @business.bookable_services.new(bookable_service_params)

        if bookable_service.save
          render_success(
            data: BookableServicePresenter.new(bookable_service).as_json,
            message: "Bookable service created successfully",
            status: :created
          )
        else
          render_error(
            message: "Bookable service could not be created",
            errors: bookable_service.errors.full_messages
          )
        end
      end

      # OWNER ONLY
      def update
        if @bookable_service.update(bookable_service_params)
          render_success(
            data: BookableServicePresenter.new(@bookable_service).as_json,
            message: "Bookable service updated successfully"
          )
        else
          render_error(
            message: "Bookable service could not be updated",
            errors: @bookable_service.errors.full_messages
          )
        end
      end

      # OWNER ONLY
      def destroy
        @bookable_service.destroy!

        render_success(
          message: "Bookable service deleted successfully"
        )
      end

      private

      def set_business
        @business = Business.find(params[:business_id])
      end

      def set_bookable_service
        @bookable_service = BookableService.find(params[:id])
      end

      # 🔐 عند الإنشاء نتحقق من business مباشرة
      def authorize_business_owner_for_create!
        ensure_business_owner!(@business)
      end

      # 🔐 عند التعديل والحذف نتحقق عبر العلاقة
      def authorize_business_owner!
        ensure_business_owner!(@bookable_service.business)
      end

      def bookable_service_params
        params.require(:bookable_service).permit(
          :name,
          :description,
          :duration_minutes,
          :price,
          :is_active
        )
      end
    end
  end
end
