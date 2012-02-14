require 'date'

class Mobile::NavigationController < Mobile::MobileController
  
  # POST /mobile/options/:option_id/navigate
  def navigate
    option_id = params[:option_id]

    redirect_path = handle_nav(option_id) {|coming_from, redirect_path|
      push_to_stack = true

      if coming_from == mobile_option_initial_position_path(option_id)
        # Next from choosing initial position.  Save in session data
        if params[:position] and params[:position][:stance_bucket]
          set_position(option_id, params[:position][:stance_bucket])
        else
          # Didn't input correct data.  Tell them that
          flash[:error] = "No position chosen"
          redirect_path = request.referrer
          push_to_stack = false
        end
      elsif coming_from == mobile_option_final_position_path(option_id)
        # Next from choosing final position.  Save in session data and actually save everything
        if params[:position] and params[:position][:stance_bucket]
          position_bucket = params[:position][:stance_bucket]

          position = set_position(option_id, position_bucket)

          # Save inclusions
          if current_user
            # Get old inclusions for this option
            prev_inclusions = Inclusion.unscoped.where(:option_id => option_id, :user_id => current_user.id)

            session[option_id][:included_points].keys.each do |point_id|
              # Copy everything over if don't already exist
              prev_inclusion = prev_inclusions.where(:point_id => point_id)
              if prev_inclusion.any?
                if prev_inclusion.count == 1
                  inclusion = prev_inclusion.first
                  inclusion.update_attributes(:position_id => position.id)
                else
                  throw "Invalid inclusion count (" + prev_inclusion.count.to_s + "): " + prev_inclusion.inspect
                end
              else
                inclusion = Inclusion.new(:option_id => option_id, :position_id => position.id, :point_id => point_id, :user_id => current_user.id)
              end

              if not inclusion.save
                throw "Could not save inclusion: " + inclusion.errors
              end
            end
          else
            # TODO: Redirect to login if no current_user
            throw "Must be signed in!"
          end
        else
          # Didn't input correct data.  Tell them that
          flash[:error] = "No position chosen"
          redirect_path = request.referrer
          push_to_stack = false
        end
      end
     
      if push_to_stack
        # Push coming_from onto stack
        session[option_id][:navigate].push coming_from
      end

      redirect_path
    }

    if redirect_path.nil?
      redirect_path = handle_overview_buttons(option_id)
    end

    if redirect_path.nil?
      redirect_path = handle_points_buttons(option_id)
    end

    if redirect_path.nil?
      redirect_path = handle_add_remove_point_buttons(option_id)
    end

    if redirect_path.nil?
      redirect_path = handle_details_button(option_id)
    end

    if redirect_path.nil?
      redirect_path = handle_add_comment_button(option_id)
    end

    if redirect_path.nil?
      redirect_path = handle_segment_buttons(option_id)
    end
    
    if redirect_path.nil?
      throw "No button action for " + params[:button].keys.first.to_s
    end

    redirect_to redirect_path
  end

protected
  def set_position(option_id, stance_bucket)
    # Update session
    session[option_id][:position] = stance_bucket
    
    # Update user position if applicable
    if current_user
      positions = Position.where(:option_id => option_id, :user_id => current_user.id)
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

  def handle_nav(option_id)
    if params[:button][:home]
      # Going home.  Clear the navigation stack and go to the home side
      session[option_id][:navigate].clear
      redirect_path = mobile_home_path
    elsif params[:button][:next]
      # Next button.  Push onto stack and redirect
      coming_from = params[:button][:next].keys.first
      redirect_path = params[:button][:next][coming_from].keys.first

      redirect_path = yield(coming_from, redirect_path)
    elsif params[:button][:initiative_description]
      # Initiative Description button
      redirect_path = show_mobile_option_path(option_id)

      # Push old page onto stack
      session[option_id][:navigate].push params[:button][:initiative_description].keys.first
    elsif params[:button][:previous]
      # Back button.  Pop off stack and go back
      redirect_path = session[option_id][:navigate].pop
    end

    return redirect_path
  end

  def handle_overview_buttons(option_id)
    if params[:button][:description]
      # Show long description pushed
      redirect_path = show_mobile_option_long_description_path(params[:option_id])
    elsif params[:button][:fiscal_impact]
      redirect_path = show_mobile_option_fiscal_impact_path(params[:option_id])
    end

    if redirect_path
      # Push option overview path onto stack
      session[option_id][:navigate].push show_mobile_option_path(option_id)
    end
    
    return redirect_path
  end

  def handle_points_buttons(option_id)
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
      redirect_path = mobile_option_points_path(option_id)
    end

    if redirect_path
      # Push "my pros and cons" path onto stack
      session[option_id][:navigate].push mobile_option_points_path(option_id)
    end

    return redirect_path
  end

  def handle_add_remove_point_buttons(option_id)
    if params[:button][:remove_point]
      redirect_path = request.referrer

      point_id = params[:button][:remove_point].keys.first

      # Check if actually had that point originally
      point_is_included = false

      # Check session inclusions to remove
      if session[option_id][:included_points].keys.include? point_id
        session[option_id][:included_points].delete(point_id)
        point_is_included = true
      end

      # Check database inclusions to remove
      if current_user
        inclusions = current_user.inclusions.where(:option_id => option_id, :point_id => point_id)

        inclusions.each do |i|
          # Should only have one inclusion that matches the users option and point
          i.destroy
          point_is_included = true
        end
      end

      if !point_is_included
        throw "Point is not in your list yet"
      end
    elsif params[:button][:add_point]
      redirect_path = request.referrer

      point_id = params[:button][:add_point].keys.first

      # Check session inclusions to add (only if haven't added it yet)
      if not session[option_id][:included_points].keys.include? point_id
        session[option_id][:included_points][point_id] = 1
      end

      # Check database inclusions to add
      if current_user
        inclusions = current_user.inclusions.where(:option_id => option_id, :point_id => point_id)
        if inclusions.count == 0
          # Should not have any inclusions that match the users option and point
          # TODO: Figure out how to add inclusion if don't have a position yet
        else
          throw "Should not already have included the point: " + inclusions.inspect
        end
      end
    end

    return redirect_path
  end

  def handle_details_button(option_id)
    if params[:button][:point_details]
      referrer_path = params[:button][:point_details].keys.first
      point_id = params[:button][:point_details][referrer_path].keys.first
      redirect_path = show_mobile_option_point_path(option_id, point_id)

      # Push referrer path onto stack
      session[option_id][:navigate].push referrer_path
    end

    return redirect_path
  end

  def handle_add_comment_button(option_id)
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

  def handle_segment_buttons(option_id)
    if params[:button][:segment]
      stance_bucket = params[:button][:segment].keys.first
      
      if params[:button][:segment][stance_bucket].is_a?(Hash) and
         (params[:button][:segment][stance_bucket][:pro] or
          params[:button][:segment][stance_bucket][:con])
        # Going to the list of points for a segment
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
    end

    return redirect_path
  end
end
