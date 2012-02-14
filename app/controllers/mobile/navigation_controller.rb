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
          session[option_id][:position] = params[:position][:stance_bucket]
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
          session[option_id][:position] = position_bucket

          # Save everything
          if current_user
            # TODO: Figure out how to instantiate positions correctly (and get rid of old position)
            position = Position.new(:option_id => option_id, :user_id => current_user.id, :stance => (position_bucket.to_i / 6.0), :stance_bucket => position_bucket, :published => true)
            if position.save
              session[option_id][:included_points].keys.each do |point_id|
                # TODO: Figure out how to instantiate inclusions correctly
                inclusion = Inclusion.new(:option_id => option_id, :position_id => position.id, :point_id => point_id, :user_id => current_user.id)
                if inclusion.save
                  # All succeeded!
                  flash[:notice] = "Success!"
                else
                  throw "Could not save inclusion: " + inclusion.errors
                end
              end
            else
              throw "Could not save position: " + position.errors
            end
          else
            # TODO: Redirect to login if haven't done this
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
      # Add point to included_points
      if session[option_id][:included_points].keys.include? point_id
        session[option_id][:included_points].delete(point_id)
      else
        throw "Point is not in your list yet"
      end
    elsif params[:button][:add_point]
      redirect_path = request.referrer

      point_id = params[:button][:add_point].keys.first
      # Add point to included_points
      if session[option_id][:included_points].keys.include? point_id
        throw "Point already in your list"
      else
        session[option_id][:included_points][point_id] = 1
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
