require 'date'

class Mobile::MobileController < ApplicationController
  
  def index
    @options = Option.all
  end

  def option
    @option = Option.find_by_id(params[:option_id])
    @title = "#{@option.reference}"
    # Determine if we have the forward button available since we also link to this page 
    # from the nav and we don't want a forward option then (might be a buggy way to determine)
    if (request.referrer == mobile_home_url)
      @navigation = { :forward_path => mobile_option_initial_position_path(:option_id => @option.id) }
    else
      @navigation = {  }
    end
  end

  def option_long_description
    @option = Option.find_by_id(params[:option_id])
    @title = "#{@option.reference}"
    @navigation = {  }
  end

  def option_fiscal_impact
    @option = Option.find_by_id(params[:option_id])
    @title = "#{@option.reference}"
    @navigation = {  }
  end

  def position_initial
    @option = Option.find_by_id(params[:option_id])
    @title = "#{@option.reference}"
    @navigation = { :forward_path => mobile_option_points_path(:option_id => @option.id),
                    :link_description => true, :option_id => @option.id }
  end

  def points
    @option = Option.find_by_id(params[:option_id])
    @title = "#{@option.reference}"
    @navigation = { :forward_path => mobile_option_final_position_path(:option_id => @option.id),
                    :link_description => true, :option_id => @option.id }

    @included_pros = get_included_points(true)
    @included_cons = get_included_points(false)
  end

  def list_points
    @option = Option.find_by_id(params[:option_id])
    @title = "#{@option.reference}"
    @navigation = { :link_description => true, :option_id => @option.id }

    @type = params[:type]
    if @type == 'pro'
      @included_points = get_included_points(true)
    elsif @type == 'con'
      @included_points = get_included_points(false)
    else
      throw 'Invalid type ' + @type
    end
  end

  def add_point
    @option = Option.find_by_id(params[:option_id])
    @title = "#{@option.reference}"
    @navigation = { :link_description => true, :option_id => @option.id }
    
    @type = params[:type]
    if @type == 'pro'
      @points = @option.points.pros.not_included_by(current_user, session[@option.id][:included_points].keys).ranked_persuasiveness
    elsif @type == 'con'
      @points = @option.points.cons.not_included_by(current_user, session[@option.id][:included_points].keys).ranked_persuasiveness
    else
      throw 'Invalid type ' + @type
    end
  end

  def new_point
    @option = Option.find_by_id(params[:option_id])
    @title = "#{@option.reference}"
    @navigation = { :link_description => true, :option_id => @option.id }

    @type = params[:type]
  end

  def point_details
    @option = Option.find_by_id(params[:option_id])
    @title = "#{@option.reference}"
    @navigation = { :link_description => true, :option_id => @option.id }
    
    @point = Point.find_by_id(params[:point_id])
    if @point.option != @option
      throw "Point not valid for the specified option"
    end
  end

  def position_final
    @option = Option.find_by_id(params[:option_id])
    @title = "#{@option.reference}"
    @navigation = { :forward_path => mobile_option_summary_path(:option_id => @option.id),
                    :link_description => true, :option_id => @option.id }
  end

  def summary
    @option = Option.find_by_id(params[:option_id])
    @title = "#{@option.reference}"
    @navigation = { }
  end

  def segment
    @option = Option.find_by_id(params[:option_id])
    @title = "#{@option.reference}"
    @navigation = { }

    @segment_type = params[:segment_type]
  end

protected
  def get_included_points is_pro
    # TODO: Refactor this out since is replicated from positions_controller.rb
    return Point.included_by_stored(current_user, @option).where(:is_pro => is_pro) + 
           Point.included_by_unstored(session[@option.id][:included_points].keys, @option).where(:is_pro => is_pro)
  end
end
