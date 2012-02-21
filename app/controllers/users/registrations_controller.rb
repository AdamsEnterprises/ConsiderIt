class Users::RegistrationsController < Devise::RegistrationsController
	protect_from_forgery :except => :create

  def new
    @context = params[:context]
    super
  end

  def create
    build_resource
    is_mobile = is_mobile_call(request.referer)    

    if is_mobile
      # check for cancel button
      if params[:button][:cancel]
        redirect_to mobile_login_return_path
        return
      end
      
      # validate input
      error = true
      if params[:user][:name] == ""
        flash[:error] = "Please enter your first and last name."
      elsif params[:user][:email] == ""
        flash[:error] = "Please enter an email address."
      # email regex: a@a.a, where a is one or more non-whitespace chars
      elsif !(params[:user][:email] =~ /\A\S+@\S+\.\S+\Z/ )
        flash[:error] = "Invalid email address."
      elsif params[:user][:password].length < 6
        flash[:error] = "Password must be at least 6 characters"
      else
        error = false
      end
    end

    if !error && resource.save

      if resource.active_for_authentication?
        sign_in(resource_name, resource)
        if current_user && session[:domain] != current_user.domain_id
          current_user.domain_id = session[:domain]
          current_user.save
        end
        if session.has_key?('position_to_be_published')
          session['reify_activities'] = true 
        end

        if is_mobile
          # redirect to instructions about confirmation on success
          redirect_to new_mobile_user_confirm_path
	else
          redirect_to request.referer
        end
      else
        set_flash_message :notice, :inactive_signed_up, :reason => inactive_reason(resource) if is_navigational_format?
        expire_session_data_after_sign_in!
        respond_with resource, :location => after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords(resource)

      if is_mobile
        # redirect to signup page on fail
        if !error
          flash[:error] = "Email is already in use."
        end
        redirect_to request.referrer
      else
        respond_with_navigational(resource) { render_with_scope :new }
      end
    end
    
  end
  def update
    current_user.update_attributes(params[:user])
    current_user.save
    pp current_user
    redirect_to request.referer
  end
end
