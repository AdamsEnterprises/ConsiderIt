require 'date'

class Mobile::MobileController < ApplicationController
  
  def index
    @options = Option.all
  end

  def option
    @option = Option.find_by_id(params[:option_id])
    @title = "#{@option.reference}"
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