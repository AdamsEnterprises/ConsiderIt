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
  end

  def add_point
  end

  def new_point
  end

  def point_details
  end

  def review
  end

  def summary
  end

end
