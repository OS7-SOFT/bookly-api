module Api
  module V1
    class AuthController < ApplicationController
      before_action :authenticate_user!, only: [ :me ]

      def register
        user = User.new(register_params)

        if user.save
          render_success(
            data: auth_payload(user),
            message: "Account created successfully",
            status: :created
          )
        else
          render_error(
            message: "Account could not be created",
            errors: user.errors.full_messages
          )
        end
      end

      def login
        user = User.find_by(email: login_params[:email].to_s.strip.downcase)

        if user&.authenticate(login_params[:password])
          render_success(
            data: auth_payload(user),
            message: "Logged in successfully"
          )
        else
          render_error(
            message: "Invalid email or password",
            errors: [ "Invalid email or password" ],
            status: :unauthorized
          )
        end
      end

      def me
        render_success(
          data: {
            user: UserPresenter.new(current_user).as_json
          }
        )
      end

      private

      def register_params
        params.require(:user).permit(
          :full_name,
          :email,
          :password,
          :password_confirmation
        )
      end

      def login_params
        params.require(:user).permit(
          :email,
          :password
        )
      end

      def auth_payload(user)
        {
          user: UserPresenter.new(user).as_json,
          token: JsonWebToken.encode({ user_id: user.id })
        }
      end
    end
  end
end
