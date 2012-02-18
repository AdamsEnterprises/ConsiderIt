module Mobile::MobileHelper
  def is_login_page
    path = request.request_uri
    return (path == mobile_user_path ||
            path == new_mobile_user_path ||
            path == new_mobile_user_pledge_path ||
            path == new_mobile_user_confirm_path ||
            path == new_mobile_password_path ||
            path == mobile_confirm_resend_path)
  end

  def get_page_name(path = request.request_uri)
    if path == mobile_home_path
      page_name = "Homepage"
    elsif path == mobile_user_path
      page_name = "Log In to the Living Voters Guide"
    elsif path == new_mobile_user_why_path
      page_name = "Why Join ConsiderIt?"
    elsif path == new_mobile_user_path
      page_name = "Join the Living Voters Guide"
    elsif path == new_mobile_user_pledge_path
      page_name = "Participant Pledge"
    elsif path == new_mobile_user_confirm_path
      page_name = "Welcome to the ConsiderIt Community!"
    elsif path == new_mobile_password_path
      page_name = "Forgot Your Password?"
    elsif path == mobile_confirm_resend_path
      page_name = "Didn't receive confirmation instructions?"
    elsif path == mobile_tou_path
      page_name = "ConsiderIt Terms of Use"
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
        page_name = "My Pros and Cons"
      elsif path == mobile_option_list_points_path(@option, :pro)
        page_name = "My Pros"
      elsif path == mobile_option_list_points_path(@option, :con)
        page_name = "My Cons"
      elsif path == add_mobile_option_point_path(@option, :pro)
        page_name = "Add an Existing Pro"
      elsif path == add_mobile_option_point_path(@option, :con)
        page_name = "Add an Existing Con"
      elsif path == new_mobile_option_point_path(@option, :pro)
        page_name = "Write a New Pro"
      elsif path == new_mobile_option_point_path(@option, :con)
        page_name = "Write a New Con"
      elsif path == mobile_option_final_position_path(@option)
        page_name = "Update Your Position"
      elsif path == mobile_option_summary_path(@option)
        page_name = "Voter Distribution"
      # TODO: Fix this up (won't work @point not defined)
      # elsif @point and path == show_mobile_option_point_path(@option, @point)
      # TEMPTEMP Fix for it (only works because no other path has this)
      elsif path.starts_with?(mobile_option_points_path(@option) + "/") and path.match(/(.+[0-9]+$)/i)
        page_name = "Point Details"
      else
        (0..7).each do |stance_bucket|
          if path == mobile_option_segment_path(@option, stance_bucket)
            temp = "$' Pros and Cons"
          elsif path == mobile_option_segment_list_path(@option, stance_bucket, :pro)
            temp = "Pros Chosen By $"
          elsif path == mobile_option_segment_list_path(@option, stance_bucket, :con)
            temp = "Cons Chosen By $"
          end

          # Set up either stance name or "All Voters"...only if actually set page_name
          if temp
            if stance_bucket == 7
              segment = "All Voters"
            else
              segment = @stance_name.split(" ").each{|word| word.capitalize!}.join(" ")
            end
            page_name = temp.gsub("$", segment)
          end
        end
      end

    end
    
    if page_name.nil?
      throw "Unrecognized Path: " + path# + ", " + Routing::Routes.recognize(path)
    end

    return page_name
  end

  def resource_name
    :user
  end

  def resource
    @resource ||= User.new
  end

  def devise_mapping
    @device_mapping ||= Devise.mappings[:user]
  end

end
