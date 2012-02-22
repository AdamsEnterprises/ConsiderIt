

class Users::PasswordsController < Devise::PasswordsController
  skip_before_filter :require_no_authentication

  def create
    self.resource = resource_class.send_reset_password_instructions(params[resource_name])

    if resource.errors.empty?
      respond_with({}, :location => after_sending_reset_password_instructions_path_for(resource_name))
    else
      if /^\/mobile/ === URI(request.referrer).path
        flash[:notice] = "Email " + resource.errors[:email][0]
        redirect_to request.referrer
      else
        respond_with(resource)
      end
    end
  end

  # GET /resource/password/edit?reset_password_token=abcdef
  def edit
    is_mobile_request = params[:mobile]

    if is_mobile_request
      if current_user
        flash[:error] = "Already logged in!"
        redirect_to mobile_home_path and return
      end
    else
      require_no_authentication
    end

    self.resource = resource_class.new
    resource.reset_password_token = params[:reset_password_token]

    if is_mobile_request
      redirect_to edit_mobile_password_path(:token => params[:reset_password_token])
    end
  end

  # PUT /resource/password
  def update
    is_mobile = /^\/mobile/ === URI(request.referrer).path
    self.resource = resource_class.reset_password_by_token(params[resource_name])

    if resource.errors.empty?
      flash_message = resource.active_for_authentication? ? :updated : :updated_not_active
      set_flash_message(:notice, flash_message) if is_navigational_format?
      sign_in(resource_name, resource)

      if is_mobile
        redirect_to mobile_home_path
      else
        respond_with resource, :location => after_sign_in_path_for(resource)
      end
    else
      if is_mobile
        if resource.errors[:reset_password_token][0]
          flash[:error] = "Reset token #{resource.errors[:reset_password_token][0]}"
        elsif resource.errors[:password][0]
          flash[:error] = "Password #{resource.errors[:password][0]}"
        else
          flash[:error] = resource.errors
        end
        redirect_to request.referrer
      else
        respond_with resource
      end
    end
  end

  protected

    def after_sending_reset_password_instructions_path_for(resource)
      if /^\/mobile/ === URI(request.referrer).path
        flash[:notice] = "You will receive an email with instructions about how to reset your password in a few minutes. Be sure to check your junk mail folder"
        return request.referrer
      else
        super
      end
    end

end

