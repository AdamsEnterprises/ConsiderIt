require 'date'

class Mobile::NavigationController < Mobile::MobileController
  
  # GET /mobile/options/navigate/login
  def login
    if !session[:mobile].any?
      throw "No Options!"
    end

    session[:mobile].keys.each do |optionid|
      sync(optionid)
    end

    redirect_to mobile_login_return_path
  end

  # POST /mobile/user/new/complete
  def new_user_complete
    redirect_to mobile_login_return_path
  end

  # POST /mobile/user/new
  def user_pledge_submit
    if params[:button][:cancel]
      redirect_to mobile_login_return_path
    else
      redirect_to new_mobile_user_path
    end
  end

  def point_comment
  end

  # POST /mobile/options/:option_id/navigate/position
  def position_update
    if params[:button][:cancel]
      if referring_path == mobile_option_initial_position_path
        redirect_path = show_mobile_option_path
      else
        redirect_path = mobile_option_points_path
      end
    elsif params[:position] and params[:position][:stance_bucket]
      session[:mobile][option_id][:position] = params[:position][:stance_bucket]

      redirect_path = mobile_option_points_path
    else
      # Didn't input correct data.  Tell them that
      flash[:error] = "No position chosen"
      redirect_path = request.referrer
      success = false
    end

    handle_redirection redirect_path
  end

  #POST /mobile/options/option_id/navigate/point/comment
  def point_comment
    # Add comment
    comment = Comment.new(params[:comment])
    if comment.save
      # Worked.  Redirect to where came from
      handle_redirection request.referrer
    else
      throw "Could not save comment: " + comment.errors
    end
  end

  # POST /mobile/options/:option_id/navigate/add_remove_point/
  def add_remove_point
    if params[:button][:remove_point]
      point_id = params[:button][:remove_point].keys.first.to_i

      remove_inclusion(point_id)

      flash[:notice] = "Successfully removed point"

      redirect_path = request.referrer
    elsif params[:button][:add_point]
      point_id = params[:button][:add_point].keys.first.to_i

      add_inclusion(point_id)

      flash[:notice] = "Successfully added point"

      redirect_path = request.referrer
    elsif params[:button][:delete_point]
      point_id = params[:button][:delete_point].keys.first.to_i

      # Check session inclusions to remove
      if session[:mobile][option_id][:included_points].keys.include?(point_id)
        session[:mobile][option_id][:included_points].delete(point_id)
      end
      session[:mobile][option_id][:written_points].delete(point_id)

      # Delete point from DB
      point = Point.unscoped.find_by_id(point_id)
      point.destroy

      flash[:notice] = "Successfully deleted point"

      # If coming from point details, redirect to previous page
      if referring_path == show_mobile_option_point_path(:option_id => option_id,
                                                         :point_id => point_id)
        redirect_path = session[:point_return_to] || mobile_option_points_path
      else
        redirect_path = request.referrer
      end
    end

    sync

    handle_redirection redirect_path
  end

  # POST /mobile/options/:option_id/navigate/new_point/:type
  def new_point

    if params[:button][:add_point]
      @point = Point.new(params[:point])
      #throw @point.inspect
      if @point.save
        # Add point to included points
        session[:mobile][option_id][:included_points][@point.id] = 1
        # Add point to written points
        session[:mobile][option_id][:written_points].push(@point.id)

        # Update database if logged in
        sync

        # Redirect to listing user points
        redirect_path = mobile_option_list_points_path
      else
        throw "Could not save point " + @point.errors.inspect
      end
    end

    handle_redirection redirect_path
  end

protected
  def option_id
    return params[:option_id].to_i
  end

  def sync(optionid = option_id)
    # First position (since the position is needed for some points)
    sync_position(optionid)
    # Then inclusions/points
    sync_inclusions(optionid)
  end

  def sync_position(optionid = option_id)
    if current_user
      # Only if logged in
      stance_bucket = session[:mobile][optionid][:position]
      if !stance_bucket.nil?
        # Only sync up if have a session position to sync
        stance = stance_bucket.to_i / 6.0
        positions = current_user.positions.where(:option_id => optionid).order("updated_at DESC")
        if positions.any?
          # Update latest position
          position = positions.first

          # Get rid of all the old positions...only update the latest position 
          # (for some reason, there were multiple positions sometimes)
          if positions.count != 1
            positions.each do |pos|
              if pos != position
                pos.destroy
              end
            end
          end

          # Update stance for position
          position.update_attributes(:stance => stance, :stance_bucket => stance_bucket)
        else
          # Make new position (no old positions exist for this option)
          position = Position.new(:option_id => optionid, :user_id => current_user.id, :stance => stance, :stance_bucket => stance_bucket, :published => true)
        end

        if not position.save
          throw "Could not save position: " + position.inspect
        end
      end
    end
  end

  def add_inclusion(point_id, optionid = option_id)
    if current_user
      # Add to DB

      prev_inclusion = current_user.inclusions.where(:option_id => optionid, :point_id => point_id)
      if !prev_inclusion.any?
        # Only make new inclusion if haven't done it one yet
        inclusion = Inclusion.new(:option_id => optionid, :point_id => point_id, :user_id => current_user.id)

        # Set position of inclusion
        user_position_array = current_user.positions.where(:option_id => optionid)
        if user_position_array.any?
          inclusion.position_id = user_position_array.first.id
        end

        # Save inclusion
        if not inclusion.save
          throw "Could not save inclusion " + inclusion.errors.inspect
        end
      end
    else
      # Add to Session
      session[:mobile][optionid][:included_points][point_id] = 1
    end
  end

  def remove_inclusion(point_id, optionid = option_id)
    if current_user
      prev_inclusions = current_user.inclusions.where(:option_id => optionid, :point_id => point_id)
      if prev_inclusions.any? && prev_inclusions.count == 1
        inclusion = prev_inclusions.first

        # Destroy inclusion
        inclusion.destroy
      else
        throw "Cannot remove point: Point has been included #{prev_inclusions.count} times"
      end
    else
      # Check session inclusions to remove
      if session[:mobile][option_id][:included_points].keys.include?(point_id)
        session[:mobile][option_id][:included_points].delete(point_id)
      else
        throw "Cannot remove point: Point not included"
      end
    end
  end

  def sync_inclusions(optionid = option_id)
    if current_user
      # Go through all included points
      session[:mobile][optionid][:included_points].keys.each do |point_id|
        add_inclusion(point_id, optionid)
      end
      session[:mobile][optionid][:included_points] = {} # Clear inclusions

      # Go through all written points
      session[:mobile][optionid][:written_points].each do |point_id|
        point = Point.unscoped.find_by_id(point_id)

        if point.nil?
          throw "No written point with id " + point_id.to_s
        end

        point.update_attributes(:user_id => current_user.id, :published => true)
        if !point.save
          throw "Could not publish point with id " + point_id.to_s
        end
      end
      session[:mobile][optionid][:written_points] = [] # Clear written points at end
      
    end
  end

  def handle_redirection redirect_path
    # sync up DB if user logged in
    sync

    redirect_to redirect_path
  end
end
