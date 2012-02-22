require 'uri'

class ApplicationController < ActionController::Base
  #protect_from_forgery
  theme :theme_resolver

  def render(*args)
    if args
      args.first[:layout] = false if request.xhr? and args.first[:layout].nil?
    end
    @domain = session.has_key?(:domain) ? Domain.find(session[:domain]) : nil
    super
  end
    
private
  def theme_resolver
    if !session.has_key?('user_theme')
      session["user_theme"] = APP_CONFIG['theme']
    end
    session["user_theme"]
  end

  def store_location(path)
    session[:return_to] = path
  end

  def after_sign_in_path_for(resource)
    if is_mobile_call(request.referrer)
      return mobile_navigate_login_path
    else
      super
    end
  end

  def after_sign_out_path_for(resource)
    if is_mobile_call(request.referrer)
      session[:mobile] = nil
      return mobile_home_path
    else
      super
    end 
  end

  # get path from request.referrer, including removing a trailing slash
  def referring_path
    path = URI(request.referrer).path
    if path.ends_with?("/")
      path.chop!
    end
    return path
  end

  def is_mobile_call(url)
    uri = URI(url)
    return /^\/mobile/ === uri.path
  end

  # Page from which the user entered the login/signup page, or home if user
  # went to login/signup directly.
  def mobile_login_return_path
    return session[:login_return_to] || mobile_home_path
  end
end
