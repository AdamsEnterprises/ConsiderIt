require 'date'

class Mobile::MobileController < ApplicationController
  before_filter :init_option_session, :except => [:index, :confirm_resend, :new_password, :edit_password, :new_user, :new_user_confirm, :new_user_pledge, :user]
  before_filter :check_login, :only => [:new_user, :new_user_pledge, :user]
  
  # GET /mobile
  def index
    if session[:domain] and session[:domain].is_a?(Fixnum)
      # Domain is set.  Get the data
      @domain = Domain.where(:identifier => session[:domain]).first()
    end
  end

  def show
    render :action => params[:page]
  end  

  # GET /mobile/user
  def user
    store_login_ref
  end

  # GET /mobile/user/new/pledge
  def new_user_pledge
    store_login_ref
  end

  # Should be called by all entry points to the login pages (i.e. all
  # login/signup-related pages that are linked from a non-login page).
  # If coming to a login page from a non-login page, stores the referrer.
  def store_login_ref
    # if coming from a non-login page, store it as the return page
    # but if coming from an external link, don't store it at all
    path = URI(request.referrer).path
    if path != "/" && !is_login_page(path)
      session[:login_return_to] = request.referrer
    end
  end

  # GET /mobile/options/:option_id
  def option
    define_position

    # if redirected from option long description, option details, or login,
    # use the stored referrer path. If navigated directly here, don't use
    # any previous path. (Don't use the session variable because it's from
    # another tab, and it may cause redirection due to the case statement
    # farther down.) Otherwise, store the referrer path.
    ref = referring_path()
    if ref == show_mobile_option_long_description_path ||
        ref == show_mobile_option_additional_details_path ||
        ref =~ /^\/mobile\/user/  # from login/signup
      # used stored referring path
      @prev_path = session[:option_return_to]
    elsif ref == ""
      @prev_path = nil
    else
      @prev_path = ref
      session[:option_return_to] = ref
    end

    # if redirected from home or initial position and you already have
    # a position, redirect to pros/cons. But make sure you didn't 
    if !(@position.stance_bucket.nil?) && (@prev_path == mobile_option_initial_position_path ||
                                           @prev_path == mobile_home_path)
      redirect_to mobile_option_points_path
    end

    
  end

  # GET /mobile/options/:option_id/position/initial
  def position_initial
    define_position

    define_study_objects

    # If you already have a position, either because you came here directly
    # or because you redirected here after login, redirect to pros/cons
    if !(@position.stance_bucket.nil?)
      redirect_to mobile_option_points_path
    end
  end

  # GET /mobile/options/:option_id/position
  def position_update
    define_position
    define_study_objects
  end

  # GET /mobile/options/:option_id/points
  def points
    define_position

    @j_bucket = 'self'
    define_study_objects

    if @position.stance_bucket.nil?
      # If don't have a position yet, redirect to set position
      redirect_to mobile_option_initial_position_path
    end

    @included_pros = get_included_points(true)
    @included_cons = get_included_points(false)
  end

  # GET /mobile/options/:option_id/points/list/:type
  def list_points
    @type = params[:type]
    if @type == 'pro'
      @included_points = get_included_points(true)
    elsif @type == 'con'
      @included_points = get_included_points(false)
    else
      throw 'Invalid type ' + @type
    end

    @j_bucket = 'self'
    @j_context = nil # looking at own points list
    define_study_objects
  end

  # GET /mobile/options/:option_id/points/add/:type
  def add_point
    @type = params[:type]
    if @type == 'pro'
      @points = @option.points.pros.not_included_by(current_user, session[:mobile][@option.id][:included_points].keys).ranked_persuasiveness
      @included_points = get_included_points(true)
    elsif @type == 'con'
      @points = @option.points.cons.not_included_by(current_user, session[:mobile][@option.id][:included_points].keys).ranked_persuasiveness
      @included_points = get_included_points(false)
    else
      throw 'Invalid type ' + @type
    end

    define_study_objects
    PointListing.transaction do
      @included_points.each do |pnt|
        PointListing.create!(
          :option => @option,
          :position_id => @j_position_id,
          :session_id => request.session_options[:id],
          :point => pnt,
          :user => current_user,
          :context => 2
        )
      end
    end
  end

  # GET /mobile/options/:option_id/points/new/:type
  def new_point
    @point = Point.new
    @type = params[:type]
  end

  # GET /mobile/options/:option_id/points/:point_id
  def point_details    
    # if redirected from this page itself, option description, or login,
    # use the stored referrer path. Otherwise, store the referrer path.
    # If arrived directly and have no stored path, redirect to home.
    ref = referring_path()
    if ref == show_mobile_option_path ||
        ref == show_mobile_option_point_path ||
        is_login_page(ref) ||
        ref == ""
      @prev_path = session[:point_return_to] || mobile_home_path
    else
      @prev_path = ref
      session[:point_return_to] = ref
    end

    @point = Point.unscoped.find_by_id(params[:point_id])
    @included_points = get_included_points(@point.is_pro)
    if @point.option != @option
      throw "Point not valid for the specified option"
    end

    @j_point_id = @point.id
    define_study_objects
  end

  # GET /mobile/options/:option_id/summary
  def summary
    if !current_user
      redirect_to mobile_user_path
    end

    define_position

    if @position.stance_bucket.nil?
      # If don't have a position yet, redirect to set position
      redirect_to mobile_option_update_position_path
    end

  end

  # GET /mobile/options/:option_id/segment/:stance_bucket
  def segment
    @points = @option.points
    @pro_points = @points.pros
    @con_points = @points.cons

    @stance_bucket = params[:stance_bucket].to_i
    if (@stance_bucket == 7)
      @pro_points = @pro_points.ranked_overall
      @con_points = @con_points.ranked_overall
    else
      @pro_points = @pro_points.ranked_for_stance_segment(@stance_bucket)
      @con_points = @con_points.ranked_for_stance_segment(@stance_bucket)
    end

    set_stance_name(@stance_bucket)
  end

  # GET /mobile/options/:option_id/segment/:stance_bucket/:point_type
  def segment_list
    #TODO: Refactor this out since copied from points_controller (index)
    qry = @option.points

    @point_type = params[:point_type]
    if ( @point_type == 'pro' )
      qry = qry.pros
      @included_points = get_included_points(true)
    elsif ( @point_type == 'con' )
      qry = qry.cons
      @included_points = get_included_points(false)
    else
      throw 'Invalid point type ' + @point_type
    end
    
    @stance_bucket = params[:stance_bucket].to_i
    if @stance_bucket == 7
      ## All voters
      qry = qry.ranked_overall
      @j_bucket = 'all'
    else
      ## specific voter segment...
      qry = qry.ranked_for_stance_segment(@stance_bucket)
      @j_bucket = @stance_bucket
    end

    @j_context = 5 # load of voter segment on options page
    define_study_objects

    PointListing.transaction do
      @included_points.each do |pnt|
        PointListing.create!(
          :option => @option,
          :position_id => @j_position_id,
          :session_id => request.session_options[:id],
          :point => pnt,
          :user => current_user,
          :context => @j_context
        )
      end
    end

    set_stance_name(@stance_bucket)

    @points = qry
    
  end

  # GET /mobile/user/new
  def new_user
    if URI(request.referrer).path != new_mobile_user_pledge_path && URI(request.referrer).path != new_mobile_user_path
      redirect_to new_mobile_user_pledge_path
    end
  end

  # GET /mobile/user/new/confirm
  def new_user_confirm
    if URI(request.referrer).path != new_mobile_user_path
      redirect_to new_mobile_user_pledge_path
    end
  end

  # GET /mobile/user/password/edit?reset_password_token=abcdef
  def edit_password
    @reset_token = params[:token]
  end

protected
  def init_option_session
    @option = Option.find_by_id(params[:option_id])

    # Initialize the session data for the option
    if session[:mobile].nil?
      session[:mobile] = {}
    end
    if @option
      if session[:mobile][@option.id].nil?
        session[:mobile][@option.id] = {
                                :included_points => { }, # No included points at first
                                :deleted_points => { },  # No deleted points at first
                                :written_points => []    # No written points at first
                              }
      end
      if session[:mobile][@option.id][:included_points].nil?
        session[:mobile][@option.id][:included_points] = { } # No included points at first
      end
      if session[:mobile][@option.id][:deleted_points].nil?
        session[:mobile][@option.id][:deleted_points] = { }  # No deleted points at first
      end
      if session[:mobile][@option.id][:written_points].nil?
        session[:mobile][@option.id][:written_points] = []   # No written points at first
      end
    end
  end

  def check_login
    if current_user
      redirect_to mobile_home_path
    end
  end

  def define_position
    if current_user
      @position = current_user.positions.where(:option_id => @option.id).order("updated_at DESC").first
    end

    if @position.nil?
      @position = Position.new(:stance_bucket => session[:mobile][@option.id][:position])
    end
  end

  def get_included_points is_pro
    return Point.included(current_user, session[:mobile][@option.id][:included_points], is_pro, @option)
  end

  def set_stance_name(stance_bucket)
    @j_bucket = stance_bucket
    case stance_bucket
      when 7
        @stance_name = "all users"
        @j_bucket = 'all'
      when 6
        @stance_name = "strong supporters"
      when 5
        @stance_name = "moderate supporters"
      when 4
        @stance_name = "slight supporters"
      when 3
        @stance_name = "undecided voters"
      when 2
        @stance_name = "slight opposers"
      when 1
        @stance_name = "moderate opposers"
      when 0
        @stance_name = "strong opposers"
      else
        throw "Invalid stance bucket " + @stance_bucket
    end

    define_study_objects
  end

  def define_study_objects
    @j_option_id = @option.id
    if current_user && current_user.positions.where(:option_id => @j_option_id).any?
      @j_position_id = current_user.positions.where(:option_id => @j_option_id).first.id
    else
      @j_position_id = nil
    end
  end

  def is_login_page(path)
    return path =~ /^\/mobile\/user/
  end
end
