class CustomFailure < Devise::FailureApp

  # if login fails from mobile site, redirect to the mobile login page instead of main page
  def redirect_url

    if warden.message == :unconfirmed
      flash[:error] = "You have to confirm your account before continuing."
      return mobile_confirm_resend_path
    end

    if /^\/mobile/ === URI(request.referrer).path
      flash[:error] = "Invalid email or password"
      return request.referrer
    else
      super
    end
  end

  def respond
    if http_auth?
      http_auth
    else
      redirect
    end
  end
end
