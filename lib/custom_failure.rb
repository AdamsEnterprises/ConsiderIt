class CustomFailure < Devise::FailureApp

  # if login fails from mobile site, redirect to the mobile login page instead of main page
  def redirect_url
    if /^\/mobile/ === URI(request.referrer).path
      # TODO: style this flash in the view
      flash[:notice] = "Invalid email or password"
      request.referrer
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
