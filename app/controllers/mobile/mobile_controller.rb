require 'date'

class Mobile::MobileController < ApplicationController
  
  # GET /mobile
  def index
    @options = Option.all
  end

  # GET /mobile/options/:option_id
  def option
    @option = Option.find_by_id(params[:option_id])

    # Initialize the session data for the option
    if session[@option.id].nil?
      session[@option.id] = {
                              :included_points => { }, # No included points at first
                              :navigate => []          # Navigate used to move next/previous in mobile site
                            }
    end
    if session[@option.id][:included_points].nil?
      session[@option.id][:included_points] = { } # No included points at first
    end
    if (session[@option.id][:navigate].nil? or 
        session[@option.id][:navigate].empty? or 
        request.referrer == mobile_home_url)
      session[@option.id][:navigate] = [] # Navigate used to move next/previous in mobile site

      # Set initial navigate to home path
      session[@option.id][:navigate].push(mobile_home_path)
    end


    # Determine if we have the forward button available since we also link to this page 
    # from the nav and we don't want a forward option then (might be a buggy way to determine)
    if (session[@option.id][:navigate].last == mobile_home_path)
      define_navigation mobile_option_initial_position_path(@option)
    else
      define_navigation
    end
  end

  # POST /mobile/options/:option_id/navigate
  def navigate
    option_id = params[:option_id]

    if params[:button][:home]
      # Going home.  Clear the navigation stack and go to the home side
      session[option_id][:navigate].clear
      redirect_path = mobile_home_path
    elsif params[:button][:next]
      # Next button.  Push onto stack and redirect
      coming_from = params[:button][:next].keys.first
      redirect_path = params[:button][:next][coming_from].keys.first
      push_to_stack = true

      if coming_from == mobile_option_initial_position_path(option_id)
        # Next from choosing initial position.  Save in session data
        if params[:position] and params[:position][:stance_bucket]
          session[option_id][:position] = params[:position][:stance_bucket]
        else
          # Didn't input correct data.  Tell them that
          flash[:error] = "No position chosen"
          redirect_path = request.referrer
          push_to_stack = false
        end
      elsif redirect_path == nil
      end

      if push_to_stack
        # Push coming_from onto stack
        session[option_id][:navigate].push coming_from
      end
    elsif params[:button][:initiative_description]
      # Initiative Description button
      redirect_path = show_mobile_option_path(option_id)

      # Push old page onto stack
      session[option_id][:navigate].push params[:button][:initiative_description].keys.first
    elsif params[:button][:previous]
      # Back button.  Pop off stack and go back
      redirect_path = session[option_id][:navigate].pop
    elsif params[:button][:description]
      # Show long description pushed
      redirect_path = show_mobile_option_long_description_path(params[:option_id])

      # Push option overview path onto stack
      session[option_id][:navigate].push show_mobile_option_path(option_id)
    elsif params[:button][:fiscal_impact]
      redirect_path = show_mobile_option_fiscal_impact_path(params[:option_id])

      # Push option overview path onto stack
      session[option_id][:navigate].push show_mobile_option_path(option_id)
    elsif params[:button][:my_pros]
      redirect_path = mobile_option_list_points_path(option_id, :pro)

      # Push "my pros and cons" path onto stack
      session[option_id][:navigate].push mobile_option_points_path(option_id)
    elsif params[:button][:add_pros]
      redirect_path = add_mobile_option_point_path(option_id, :pro)

      # Push "my pros and cons" path onto stack
      session[option_id][:navigate].push mobile_option_points_path(option_id)
    elsif params[:button][:new_pro]
      redirect_path = new_mobile_option_point_path(option_id, :pro)

      # Push "my pros and cons" path onto stack
      session[option_id][:navigate].push mobile_option_points_path(option_id)
    elsif params[:button][:my_cons]
      redirect_path = mobile_option_list_points_path(option_id, :con)

      # Push "my pros and cons" path onto stack
      session[option_id][:navigate].push mobile_option_points_path(option_id)
    elsif params[:button][:add_cons]
      redirect_path = add_mobile_option_point_path(option_id, :con)

      # Push "my pros and cons" path onto stack
      session[option_id][:navigate].push mobile_option_points_path(option_id)
    elsif params[:button][:new_con]
      redirect_path = new_mobile_option_point_path(option_id, :con)

      # Push "my pros and cons" path onto stack
      session[option_id][:navigate].push mobile_option_points_path(option_id)
    elsif params[:button][:my_points]
      redirect_path = mobile_option_points_path(option_id)

      # Push "my pros and cons" path onto stack
      session[option_id][:navigate].push mobile_option_summary_path(option_id)
    elsif params[:button][:segment]
      stance_bucket = params[:button][:segment].keys.first
      
      if params[:button][:segment][stance_bucket].is_a?(Hash) and
         (params[:button][:segment][stance_bucket][:pro] or
          params[:button][:segment][stance_bucket][:con])
        # Going to the list of segments
        redirect_path = mobile_option_segment_list_path(option_id, stance_bucket,
                                                   params[:button][:segment][stance_bucket].keys.first)
        # Push segment overview path onto stack
        session[option_id][:navigate].push mobile_option_segment_path(option_id, stance_bucket)
      else
        # Going to segment overview
        redirect_path = mobile_option_segment_path(option_id, stance_bucket)
        # Push summary path onto stack
        session[option_id][:navigate].push mobile_option_summary_path(option_id)
      end
    else
      throw "No button action for " + params[:button].keys.first.to_s
    end

    redirect_to redirect_path
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
    @data = Position.new(:stance_bucket => session[@option.id][:position])
  end

  # GET /mobile/options/:option_id/points
  def points
    @option = Option.find_by_id(params[:option_id])
    @title = "#{@option.reference}"

    # Determine if we have the forward button available since we link to this page from 
    # from the initial position and summary pages and we don't want a forward option when
    # coming from summary (might be a buggy way to determine...copied from option)
    if (session[@option.id][:navigate].last == mobile_option_initial_position_path(@option.id))
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
      @points = @option.points.pros.not_included_by(current_user, session[@option.id][:included_points].keys).ranked_persuasiveness
    elsif @type == 'con'
      @points = @option.points.cons.not_included_by(current_user, session[@option.id][:included_points].keys).ranked_persuasiveness
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
    @data = Position.new(:stance_bucket => session[@option.id][:position])
    define_navigation mobile_option_summary_path(@option), true
  end

  # GET /mobile/options/:option_id/summary
  def summary
    @option = Option.find_by_id(params[:option_id])
    @title = "#{@option.reference}"
    define_navigation nil, true

    @user_position = current_user ? current_user.positions.where(:option_id => @option.id).first : nil
    # User stance bucket for this option (either -1 for no stance or a value in [0,6])
    @user_stance_bucket = @user_position.nil? ? -1 : @user_position.stance_bucket
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
    elsif ( @point_type == 'con' )
      qry = qry.cons
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
      @navigation = { :previous => { :path => session[@option.id][:navigate].last } }
    else
      @navigation = { :next => { :path => next_path }, 
                      :previous => { :path => session[@option.id][:navigate].last } 
                    }
    end

    if show_description
      @navigation[:show_description] = true
    end
  end

  def get_included_points is_pro
    #TEMPTEMP: Use this until get session setting correct(just handle null cases)
    if session[@option.id]
      # TODO: Refactor this out since is replicated from positions_controller.rb
      return Point.included_by_stored(current_user, @option).where(:is_pro => is_pro) + 
             Point.included_by_unstored(session[@option.id][:included_points].keys, @option).where(:is_pro => is_pro)
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
        @stance_name = "slightly opposed voters"
      when 1
        @stance_name = "moderately opposed voters"
      when 0
        @stance_name = "strongly opposed voters"
      else
        throw "Invalid stance bucket " + @stance_bucket
    end
  end
end
