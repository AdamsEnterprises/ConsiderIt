

class Users::PasswordsController < Devise::PasswordsController

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

  protected

    def after_sending_reset_password_instructions_path_for(resource)
      if /^\/mobile/ === URI(request.referrer).path
        flash[:notice] = "You will receive an email with instructions about how to reset your password in a few minutes. \nBe sure to check your junk mail folder"
        return request.referrer
      else
        super
      end
    end


end

