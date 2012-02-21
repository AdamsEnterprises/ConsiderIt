class Users::ConfirmationsController < Devise::ConfirmationsController

  # POST /resource/confirmation
  def create
    self.resource = resource_class.send_confirmation_instructions(params[resource_name])

    if resource.errors.empty?
      respond_with({}, :location => after_resending_confirmation_instructions_path_for(resource_name))
    else
      if /^\/mobile/ === URI(request.referrer).path
        flash[:notice] = "Email " + resource.errors[:email][0]
        redirect_to request.referrer
      else
        respond_with(resource)
      end
    end
  end

  protected

    # The path used after resending confirmation instructions.
    def after_resending_confirmation_instructions_path_for(resource_name)
      if /^\/mobile/ === URI(request.referrer).path
         flash[:notice] = "Confirmation instructions sent!"
         return request.referrer
      else
         new_session_path(resource_name)
      end
    end

    # The path used after confirmation.
    def after_confirmation_path_for(resource_name, resource)
      after_sign_in_path_for(resource)
    end
end

