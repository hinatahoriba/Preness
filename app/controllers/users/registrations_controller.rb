module Users
  class RegistrationsController < Devise::RegistrationsController
    protected

    def after_inactive_sign_up_path_for(resource)
      session[:pending_confirmation_email] = resource.email
      user_confirmation_pending_path
    end

    def after_update_path_for(resource)
      if resource.pending_reconfirmation?
        session[:pending_confirmation_email] = resource.unconfirmed_email
        user_confirmation_pending_path
      else
        super
      end
    end
  end
end
