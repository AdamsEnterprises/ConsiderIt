class Users::ConfirmationsController < Devise::ConfirmationsController

  # POST /resource/confirmation
  def create
    self.resource = resource_class.send_confirmation_instructions(params[resource_name])

    if resource.errors.empty?
      respond_with({}, :location => after_resending_confirmation_instructions_path_for(resource_name))
    else
      if /^\/mobile/ === URI(request.referrer).path
        flash[:error] = "Email " + resource.errors[:email][0]
        redirect_to request.referrer
      else
        respond_with(resource)
      end
    end
  end

  # GET /resource/confirmation?confirmation_token=abcdef
  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])
    is_mobile_request = params[:mobile]

    if resource.errors.empty?
      set_flash_message(:notice, :confirmed) if is_navigational_format?
      sign_in(resource_name, resource)

      if is_mobile_request
        redirect_to mobile_home_path
      else
        respond_with_navigational(resource){ redirect_to after_confirmation_path_for(resource_name, resource) }
      end
    else
      if is_mobile_request
        flash[:error] = "Confirmation token " + resource.errors[:confirmation_token][0]
        redirect_to mobile_confirm_resend_path
      else
        respond_with_navigational(resource.errors, :status => :unprocessable_entity){ render :new }
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
end

