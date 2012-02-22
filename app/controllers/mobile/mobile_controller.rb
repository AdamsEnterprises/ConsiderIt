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
    # use the stored referrer path. Otherwise, store the referrer path or
    # home if none exists.
    ref = referring_path()
    if ref == show_mobile_option_long_description_path ||
        ref == show_mobile_option_additional_details_path ||
        ref =~ /^\/mobile\/user/ ||
        ref == ""
      @prev_path = session[:option_return_to] || mobile_home_path
    else
      @prev_path = ref
      session[:option_return_to] = ref
    end
  end

  # GET /mobile/options/:option_id/description
  def option_long_description
#    define_navigation
  end

  # GET /mobile/options/:option_id/additional_details
  def option_additional_details
#    define_navigation
  end

  # GET /mobile/options/:option_id/position/initial
  def position_initial
    define_position

    # If you already have a position, either because you came here directly
    # or because you redirected here after login, redirect to pros/cons
    if !@position.stance_bucket.nil?
      redirect_to mobile_option_points_path
    end
  end

  # GET /mobile/options/:option_id/position
  def position_update
    define_position
  end

  # GET /mobile/options/:option_id/points
  def points
    define_position

    if @position.stance_bucket.nil?
      # If don't have a position yet, redirect to set position
      redirect_to mobile_option_update_position_path
    end
    
    # Determine if we have the forward button available since we link to this page from 
    # from the update position/home and summary pages and we don't want a forward option when
    # coming from summary (might be a buggy way to determine)
    if (session[:mobile][@option.id][:navigate].last == mobile_option_update_position_path(@option.id) ||
        session[:mobile][@option.id][:navigate].last == mobile_home_path)
      define_navigation mobile_option_summary_path(@option), true
    else
      define_navigation nil, true
    end

    @included_pros = get_included_points(true)
    @included_cons = get_included_points(false)
  end

  # GET /mobile/options/:option_id/points/list/:type
  def list_points
    define_navigation nil, true

    @type = params[:type]
    if @type == 'pro'
      @included_points = get_included_points(true)
    elsif @type == 'con'
      @included_points = get_included_points(false)
    else
      throw 'Invalid type ' + @type
    end
  end

  # GET /mobile/options/:option_id/points/add/:type
  def add_point
    define_navigation nil, true
    
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
  end

  # GET /mobile/options/:option_id/points/new/:type
  def new_point
    define_navigation nil, true

    @point = Point.new

    @type = params[:type]
  end

  # GET /mobile/options/:option_id/points/:point_id
  def point_details
    define_navigation nil, true
    
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
    
    define_navigation nil, true
  end

  # GET /mobile/options/:option_id/segment/:stance_bucket
  def segment
    define_navigation nil, true

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
#    define_navigation request.referrer, nil, true
    
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
    else
      ## specific voter segment...
      qry = qry.ranked_for_stance_segment(@stance_bucket)
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
                                :written_points => [],    # No written points at first
                                :navigate => []          # Navigate used to move next/previous in mobile site
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
      if (session[:mobile][@option.id][:navigate].nil? or 
          session[:mobile][@option.id][:navigate].empty? or 
          request.referrer == mobile_home_url)
        session[:mobile][@option.id][:navigate] = [] # Navigate used to move next/previous in mobile site

        # Set initial navigate to home path
        session[:mobile][@option.id][:navigate].push(mobile_home_path)
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

  def define_navigation(prev_path, next_path = nil, show_description = false, use_js_back = false)
    if next_path.nil?
      @navigation = { :previous => { :path => session[:mobile][@option.id][:navigate].last } }
    else
      @navigation = { :next => { :path => next_path }, 
                      :previous => { :path => session[:mobile][@option.id][:navigate].last } 
                    }
    end

    if show_description
      @navigation[:show_description] = true
    end
  end

  def get_included_points is_pro
    return Point.included(current_user, session[:mobile][@option.id][:included_points], is_pro, @option)
  end

  def set_stance_name(stance_bucket)
    case stance_bucket
      when 7
        @stance_name = "all users"
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
  end

  def is_login_page(path)
    return path =~ /^\/mobile\/user/
  end
end
