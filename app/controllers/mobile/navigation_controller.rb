require 'date'

class Mobile::NavigationController < Mobile::MobileController
  
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
    elsif params[:button][:remove_point]
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
    elsif params[:button][:point_details]
      referrer_path = params[:button][:point_details].keys.first
      point_id = params[:button][:point_details][referrer_path].keys.first
      redirect_path = show_mobile_option_point_path(option_id, point_id)

      # Push referrer path onto stack
      session[option_id][:navigate].push referrer_path
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
end
