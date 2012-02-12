module Mobile::MobileHelper

  def get_page_name(path = request.request_uri)
    if path == mobile_home_path
      page_name = "Homepage"
    elsif @option
      if path == show_mobile_option_path(@option)
        page_name = "#{@option.reference} Overview"
      elsif path == show_mobile_option_long_description_path(@option)
        page_name = "Long Description"
      elsif path == show_mobile_option_fiscal_impact_path(@option)
        page_name = "Fiscal Impact Statement"
      elsif path == mobile_option_initial_position_path(@option)
        page_name = "Choose an Initial Position"
      elsif path == mobile_option_points_path(@option)
        page_name = "Your Pros and Cons"
      elsif path == mobile_option_list_points_path(@option, :pro)
        page_name = "Your Pros"
      elsif path == mobile_option_list_points_path(@option, :con)
        page_name = "Your Cons"
      elsif path == add_mobile_option_point_path(@option, :pro)
        page_name = "Add an Existing Pro"
      elsif path == add_mobile_option_point_path(@option, :con)
        page_name = "Add an Existing Con"
      elsif path == new_mobile_option_point_path(@option, :pro)
        page_name = "Make a New Pro"
      elsif path == new_mobile_option_point_path(@option, :con)
        page_name = "Make a New Con"
      elsif path == mobile_option_final_position_path(@option)
        page_name = "Choose a Final Position"
      elsif path == mobile_option_summary_path(@option)
        page_name = "User Distributions"
      # TODO: Fix this up (won't work @point not defined)
      # elsif @point and path == show_mobile_option_point_path(@option, @point)
      # TEMPTEMP Fix for it (only works because no other path has this)
      elsif path.starts_with?(mobile_option_points_path(@option) + "/") and path.match(/(.+[0-9]+$)/i)
        page_name = "Point Details"
      else
        (0..7).each do |stance_bucket|
          if path == mobile_option_segment_path(@option, stance_bucket)
            temp = " Pros and Cons"
          elsif path == mobile_option_segment_list_path(@option, stance_bucket, :pro)
            temp = " Pro List"
          elsif path == mobile_option_segment_list_path(@option, stance_bucket, :con)
            temp = " Con List"
          end

          # Set up either stance name or "All Voters"...only if actually set page_name
          if temp and stance_bucket == 7
            page_name = "All voters" + temp
          elsif temp
            page_name = Position.stance_name_map(stance_bucket).capitalize + temp
          end
        end
      end

    end
    
    if page_name.nil?
      throw "Unrecognized Path: " + path# + ", " + Routing::Routes.recognize(path)
    end

    return page_name
  end

end