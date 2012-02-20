require 'date'

class Mobile::NavigationController < Mobile::MobileController
  
  # POST /mobile/options/:option_id/navigate/option
  def option
    redirect_path = handle_nav {|redirect_path|
      session[:mobile][option_id][:navigate].push show_mobile_option_path
      redirect_path
    }

    if redirect_path.nil?
      redirect_path = handle_overview_buttons
    end

    handle_redirection redirect_path
  end

  # POST /mobile/options/:option_id/navigate/long_description
  def long_description
    redirect_path = handle_nav {|redirect_path|
      throw "Should not have next for long description"
    }

    handle_redirection redirect_path
  end

  # POST /mobile/options/:option_id/navigate/additional_details
  def additional_details
    redirect_path = handle_nav {|redirect_path|
      throw "Should not have next for additional details"
    }

    handle_redirection redirect_path
  end

  # POST /mobile/options/:option_id/navigate/position
  def position_update
    if params[:position] and params[:position][:stance_bucket]
      set_position(params[:position][:stance_bucket])
      redirect_path = mobile_option_points_path
    else
      # Didn't input correct data.  Tell them that
      flash[:error] = "No position chosen"
      redirect_path = request.referrer
      success = false
    end

    handle_redirection redirect_path
  end

  # POST /mobile/options/:option_id/navigate/points
  def points
    redirect_path = handle_nav {|redirect_path|
      session[:mobile][option_id][:navigate].push mobile_option_points_path
      if current_user.nil?
        redirect_path = mobile_user_path
      else
        redirect_path
      end
    }

    if redirect_path.nil?
      redirect_path = handle_points_buttons
    end

    handle_redirection redirect_path
  end

  # POST /mobile/options/:option_id/navigate/list_points/:type
  def list_points
    redirect_path = handle_nav {|redirect_path|
      throw "Should not have next for list_points"
    }

    if redirect_path.nil?
      redirect_path = handle_add_remove_point_buttons(mobile_option_list_points_path)
    end

    if redirect_path.nil?
      redirect_path = handle_details_button
    end

    handle_redirection redirect_path
  end

  # POST /mobile/options/:option_id/navigate/add_point/:type
  def add_point
    redirect_path = handle_nav {|redirect_path|
      throw "Should not have next for add_point"
    }

    if redirect_path.nil?
      redirect_path = handle_add_remove_point_buttons(add_mobile_option_point_path)
    end

    if redirect_path.nil?
      redirect_path = handle_details_button
    end

    handle_redirection redirect_path
  end

  # POST /mobile/options/:option_id/navigate/new_point/:type
  def new_point
    redirect_path = handle_nav {|redirect_path|
      throw "Should not have next for new_point"
    }

    if params[:button][:add_point]
      @point = Point.new(params[:point])
      #throw @point.inspect
      if @point.save
        # Add point to included points
        session[:mobile][option_id][:included_points][@point.id] = 1
        # Add point to written points
        session[:mobile][option_id][:written_points].push(@point.id)

        # Update database if logged in
        update_inclusions

        # Redirect to listing user points
        redirect_path = mobile_option_list_points_path
      else
        throw "Could not save point " + @point.errors.inspect
      end
    end

    handle_redirection redirect_path
  end

  # POST /mobile/options/:option_id/navigate/point_details/:point_id
  def point_details
    redirect_path = handle_nav {|redirect_path|
      throw "Should not have next for point_details"
    }

    if redirect_path.nil?
      redirect_path = handle_add_remove_point_buttons(session[:mobile][option_id][:navigate].pop)
    end

    if redirect_path.nil?
      redirect_path = handle_add_comment_button
    end

    handle_redirection redirect_path
  end

  # POST /mobile/options/:option_id/navigate/summary
  def summary
    redirect_path = handle_nav {|redirect_path|
      throw "Should not have next for summary"
    }

    if params[:button][:my_points]
      redirect_path = mobile_option_points_path
      session[:mobile][option_id][:navigate].push mobile_option_summary_path
    end

    if redirect_path.nil?
      redirect_path = handle_segment_buttons
    end

    handle_redirection redirect_path
  end

  # POST /mobile/options/:option_id/navigate/segment/:stance_bucket
  def segment
    redirect_path = handle_nav {|redirect_path|
      throw "Should not have next for segment"
    }

    if redirect_path.nil?
      redirect_path = handle_segment_buttons
    end

    handle_redirection redirect_path
  end

  # POST /mobile/options/:option_id/navigate/segment_list/:stance_bucket/:point_type
  def segment_list
    redirect_path = handle_nav {|redirect_path|
      throw "Should not have next for segment_list"
    }

    if redirect_path.nil?
      redirect_path = handle_add_remove_point_buttons(mobile_option_segment_list_path)
    end

    if redirect_path.nil?
      redirect_path = handle_details_button
    end

    if redirect_path.nil?
      redirect_path = handle_segment_buttons
    end

    handle_redirection redirect_path
  end

protected
  def option_id
    return params[:option_id].to_i
  end

  def update_inclusions
    if current_user
      session[:mobile][option_id][:included_points].keys.each do |point_id|
        prev_inclusion = current_user.inclusions.where(:option_id => option_id, :point_id => point_id)
        if prev_inclusion.any?
          throw "Should not have included the point already"
        end
    
        inclusion = Inclusion.new(:option_id => option_id, :point_id => point_id, :user_id => current_user.id)
    
        # Set position of inclusion
        user_position_array = current_user.positions.where(:option_id => option_id)
        if user_position_array.any?
          inclusion.position_id = user_position_array.first.id
        end
    
        # Save inclusion
        if not inclusion.save
          throw "Could not save inclusion " + inclusion.errors.inspect
        end
      end
      session[:mobile][option_id][:included_points] = {} # Clear inclusions

      session[:mobile][option_id][:deleted_points].keys.each do |point_id|
        # Remove inclusion of the point
        current_user.inclusions.where(:point_id => point_id).each do |inc|
          inc.destroy
        end
      end
      session[:mobile][option_id][:deleted_points] = {} # Clear deleted points at end

      session[:mobile][option_id][:written_points].each do |point_id|
        point = Point.unscoped.find_by_id(point_id)

        if point.nil?
          throw "No written point with id " + point_id.to_s
        end

        point.update_attributes(:user_id => current_user.id, :published => true)
        if !point.save
          throw "Could not publish point with id " + point_id.to_s
        end
      end
      session[:mobile][option_id][:written_points] = [] # Clear written points at end
      
    end
  end

  def handle_redirection redirect_path
    update_inclusions
    redirect_to redirect_path
  end

  def set_position(stance_bucket)
    # Update session
    session[:mobile][option_id][:position] = stance_bucket
    
    # Update user position if applicable
    if current_user
      positions = current_user.positions.where(:option_id => option_id)
      stance = stance_bucket.to_i / 6.0
      if positions.any?
        if positions.count == 1
          position = positions.first
          position.update_attributes(:stance => stance, :stance_bucket => stance_bucket)
        else
          throw "Invalid positions count (" + positions.count.to_s + "): " + positions.inspect
        end
      else
        position = Position.new(:option_id => option_id, :user_id => current_user.id, :stance => stance, :stance_bucket => stance_bucket, :published => true)
      end

      if not position.save
        throw "Could not save position: " + position.inspect
      end
    end

    return position
  end

  def handle_nav
    if params[:button][:home]
      # Going home.  Clear the navigation stack and go to the home side
      session[:mobile][option_id][:navigate].clear
      redirect_path = mobile_home_path
    elsif params[:button][:next]
      # Next button.  Push onto stack and redirect
      redirect_path = params[:button][:next].keys.first

      redirect_path = yield(redirect_path)
    elsif params[:button][:initiative_description]
      # Initiative Description button
      redirect_path = show_mobile_option_path

      # Push old page onto stack
      session[:mobile][option_id][:navigate].push params[:button][:initiative_description].keys.first
    elsif params[:button][:previous]
      # Back button.  Pop off stack and go back
      redirect_path = session[:mobile][option_id][:navigate].pop
    end

    return redirect_path
  end

  def handle_overview_buttons
    if params[:button][:description]
      # Show long description pushed
      redirect_path = show_mobile_option_long_description_path(params[:option_id])
    elsif params[:button][:additional_details]
      redirect_path = show_mobile_option_additional_details_path(params[:option_id])
    end

    if redirect_path
      # Push option overview path onto stack
      session[:mobile][option_id][:navigate].push show_mobile_option_path
    end
    
    return redirect_path
  end

  def handle_points_buttons
    if params[:button][:my_pros]
      redirect_path = mobile_option_list_points_path(option_id, :pro)
    elsif params[:button][:add_pros]
      redirect_path = add_mobile_option_point_path(option_id, :pro)
    elsif params[:button][:new_pro]
      redirect_path = new_mobile_option_point_path(option_id, :pro)
    elsif params[:button][:my_cons]
      redirect_path = mobile_option_list_points_path(option_id, :con)
    elsif params[:button][:add_cons]
      redirect_path = add_mobile_option_point_path(option_id, :con)
    elsif params[:button][:new_con]
      redirect_path = new_mobile_option_point_path(option_id, :con)
    elsif params[:button][:my_points]
      redirect_path = mobile_option_points_path
    elsif params[:button][:update_position]
      redirect_path = mobile_option_update_position_path
    end

    if redirect_path
      # Push "my pros and cons" path onto stack
      session[:mobile][option_id][:navigate].push mobile_option_points_path
    end

    return redirect_path
  end

  def handle_add_remove_point_buttons(delete_path)
    if params[:button][:remove_point]
      redirect_path = request.referrer

      point_id = params[:button][:remove_point].keys.first.to_i

      # Check session inclusions to remove
      if session[:mobile][option_id][:included_points].keys.include?(point_id)
        session[:mobile][option_id][:included_points].delete(point_id)
      end
      session[:mobile][option_id][:deleted_points][point_id] = 1
    elsif params[:button][:add_point]
      redirect_path = request.referrer

      point_id = params[:button][:add_point].keys.first.to_i

      session[:mobile][option_id][:included_points][point_id] = 1
      if session[:mobile][option_id][:deleted_points].keys.include?(point_id)
        session[:mobile][option_id][:deleted_points].delete(point_id)
      end
    elsif params[:button][:delete_point]
      redirect_path = delete_path

      point_id = params[:button][:delete_point].keys.first.to_i

      # Check session inclusions to remove
      if session[:mobile][option_id][:included_points].keys.include?(point_id)
        session[:mobile][option_id][:included_points].delete(point_id)
      end
      session[:mobile][option_id][:written_points].delete(point_id)

      # Delete point from DB
      point = Point.unscoped.find_by_id(point_id)
      point.destroy
    end

    update_inclusions

    return redirect_path
  end

  def handle_details_button
    if params[:button][:point_details]
      referrer_path = params[:button][:point_details].keys.first
      point_id = params[:button][:point_details][referrer_path].keys.first
      redirect_path = show_mobile_option_point_path(option_id, point_id)

      # Push referrer path onto stack
      session[:mobile][option_id][:navigate].push referrer_path
    end

    return redirect_path
  end

  def handle_add_comment_button
    if params[:button][:add_comment]
      # Add comment
      comment = Comment.new(params[:navigate][:comment])
      if comment.save
        # Worked.  Redirect to where came from
        redirect_path = request.referrer
      else
        throw "Could not save comment: " + comment.errors
      end
    end

    return redirect_path
  end

  def handle_segment_buttons
    if params[:button][:segment]
      stance_bucket = params[:button][:segment].keys.first
      
      if params[:button][:segment][stance_bucket].is_a?(Hash) and
         (params[:button][:segment][stance_bucket][:pro] or
          params[:button][:segment][stance_bucket][:con])
        # Going to the list of points for a segment
        redirect_path = mobile_option_segment_list_path(option_id, stance_bucket,
                                                   params[:button][:segment][stance_bucket].keys.first)
        # Push segment overview path onto stack
        session[:mobile][option_id][:navigate].push mobile_option_segment_path(option_id, stance_bucket)
      else
        # Going to segment overview
        redirect_path = mobile_option_segment_path(option_id, stance_bucket)
        # Push summary path onto stack
        session[:mobile][option_id][:navigate].push mobile_option_summary_path
      end
    end

    return redirect_path
  end
end
