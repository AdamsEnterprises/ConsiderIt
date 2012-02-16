require 'date'

class Mobile::MobileController < ApplicationController
  
  # GET /mobile
  def index
  end

  # GET /mobile/options/:option_id
  def option
    @option = Option.find_by_id(params[:option_id])

    # Initialize the session data for the option
    if session[:mobile].nil?
      session[:mobile] = {}
    end
    if session[:mobile][@option.id].nil?
      session[:mobile][@option.id] = {
                              :included_points => { }, # No included points at first
                              :navigate => []          # Navigate used to move next/previous in mobile site
                            }
    end
    if session[:mobile][@option.id][:included_points].nil?
      session[:mobile][@option.id][:included_points] = { } # No included points at first
    end
    if (session[:mobile][@option.id][:navigate].nil? or 
        session[:mobile][@option.id][:navigate].empty? or 
        request.referrer == mobile_home_url)
      session[:mobile][@option.id][:navigate] = [] # Navigate used to move next/previous in mobile site

      # Set initial navigate to home path
      session[:mobile][@option.id][:navigate].push(mobile_home_path)
    end


    # Determine if we have the forward button available since we also link to this page 
    # from the nav and we don't want a forward option then (might be a buggy way to determine)
    if (session[:mobile][@option.id][:navigate].last == mobile_home_path)
      define_navigation mobile_option_initial_position_path(@option)
    else
      define_navigation
    end
  end

  # GET /mobile/options/:option_id/description
  def option_long_description
    @option = Option.find_by_id(params[:option_id])
    define_navigation
  end

  # GET /mobile/options/:option_id/fiscal_impact
  def option_fiscal_impact
    @option = Option.find_by_id(params[:option_id])
    define_navigation
  end

  # GET /mobile/options/:option_id/positions/initial
  def position_initial
    @option = Option.find_by_id(params[:option_id])
    define_navigation mobile_option_points_path(:option_id => @option.id), true
    @data = Position.new(:stance_bucket => session[:mobile][@option.id][:position])
  end

  # GET /mobile/options/:option_id/points
  def points
    @option = Option.find_by_id(params[:option_id])
    @title = "#{@option.reference}"

    # Determine if we have the forward button available since we link to this page from 
    # from the initial position and summary pages and we don't want a forward option when
    # coming from summary (might be a buggy way to determine...copied from option)
    if (session[:mobile][@option.id][:navigate].last == mobile_option_initial_position_path(@option.id))
      define_navigation mobile_option_final_position_path(@option), true
    else
      define_navigation nil, true
    end

    @included_pros = get_included_points(true)
    @included_cons = get_included_points(false)
  end

  # GET /mobile/options/:option_id/points/list/:type
  def list_points
    @option = Option.find_by_id(params[:option_id])
    @title = "#{@option.reference}"
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
    @option = Option.find_by_id(params[:option_id])
    @title = "#{@option.reference}"
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
    @option = Option.find_by_id(params[:option_id])
    @title = "#{@option.reference}"
    define_navigation nil, true

    @type = params[:type]
  end

  # GET /mobile/options/:option_id/points/:point_id
  def point_details
    @option = Option.find_by_id(params[:option_id])
    @title = "#{@option.reference}"
    define_navigation nil, true
    
    @point = Point.find_by_id(params[:point_id])
    if @point.option != @option
      throw "Point not valid for the specified option"
    end
  end

  # GET /mobile/options/:option_id/positions/final
  def position_final
    @option = Option.find_by_id(params[:option_id])
    @title = "#{@option.reference}"
    @data = Position.new(:stance_bucket => session[:mobile][@option.id][:position])
    define_navigation mobile_option_summary_path(@option), true
  end

  # GET /mobile/options/:option_id/summary
  def summary
    @option = Option.find_by_id(params[:option_id])
    @title = "#{@option.reference}"
    define_navigation nil, true

    # TODO: Figure out how they actually get the user position
    @user_stance_bucket = session[:mobile][@option.id][:position].to_i
  end

  # GET /mobile/options/:option_id/segment/:stance_bucket
  def segment
    @option = Option.find_by_id(params[:option_id])
    @title = "#{@option.reference}"
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
    @option = Option.find_by_id(params[:option_id])
    @title = "#{@option.reference}"
    define_navigation nil, true
    
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

protected
  def define_navigation(next_path = nil, show_description = false)
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
    #TEMPTEMP: Use this until get session setting correct(just handle null cases)
    if session[:mobile][@option.id]
      # TODO: Refactor this out since is replicated from positions_controller.rb
      return (Point.included_by_stored(current_user, @option).where(:is_pro => is_pro) + 
             Point.included_by_unstored(session[:mobile][@option.id][:included_points].keys, @option).where(:is_pro => is_pro)).uniq
    else
      return []
    end
  end

  def set_stance_name(stance_bucket)
    case stance_bucket
      when 7
        @stance_name = "all voters"
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
end
