ConsiderIt::Application.routes.draw do
  
  resources :point_links

  root :to => "home#index"
  
  resources :options, :only => [:show, :index] do
    resources :positions, :only => [:new, :edit, :create, :update, :show, :destroy]
    resources :points, :only => [:index, :create, :update, :destroy] do 
      resources :inclusions, :only => [:create] 
    end
    resources :point_similarities, :module => :admin
    resources :comments, :only => [:index, :create]
  end


  devise_for :users, :controllers => { 
    :omniauth_callbacks => "users/omniauth_callbacks", 
    :sessions => "users/sessions", 
    :registrations => "users/registrations",
    :passwords => "users/passwords",
    :confirmations => "users/confirmations"
  }

  themes_for_rails # themes_for_rails gem routes 

  match "/theme" => "theme#set", :via => :post
  match "/home/domain" => "home#set_domain", :via => :post
  match "/home/pledge" => "home#take_pledge", :via => :post
  match '/home/:page' => "home#show", :via => :get, :constraints => { :page => /terms-of-use|considerit|media|help/ } 

  match '/home/study/:category' => "home#study", :via => :post  
  match '/admin/dashboard' => "admin/dashboard#index", :via => :get, :module => :admin

  # mobile site
  match '/mobile' => "mobile/mobile#index", :via => :get, :module => :mobile, :as => :mobile_home
  match '/mobile/user' => "mobile/mobile#user", :via => :get, :module => :mobile, :as => :mobile_user
  match '/mobile/user/new' => "mobile/mobile#new_user", :via => :get, :module => :mobile, :as => :new_mobile_user
  match '/mobile/user/password/' => "mobile/mobile#password", :via => :get, :module => :mobile, :as => :mobile_password
  match '/mobile/login/new' => "mobile/mobile#new_login", :via => :get, :module => :mobile, :as => :new_mobile_login
  match '/mobile/options/:option_id' => "mobile/mobile#option", :via => :get, :module => :mobile, :as => :show_mobile_option
  match '/mobile/options/:option_id/description' => "mobile/mobile#option_long_description", :via => :get, :module => :mobile, :as => :show_mobile_option_long_description
  match '/mobile/options/:option_id/fiscal_impact' => "mobile/mobile#option_fiscal_impact", :via => :get, :module => :mobile, :as => :show_mobile_option_fiscal_impact
  match '/mobile/options/:option_id/positions/initial' => "mobile/mobile#position_initial", :via => :get, :module => :mobile, :as => :mobile_option_initial_position
  match '/mobile/options/:option_id/points' => "mobile/mobile#points", :via => :get, :module => :mobile, :as => :mobile_option_points
  match '/mobile/options/:option_id/points/list/:type' => "mobile/mobile#list_points", :via => :get, :module => :mobile, :as => :mobile_option_list_points
  match '/mobile/options/:option_id/points/add/:type' => "mobile/mobile#add_point", :via => :get, :module => :mobile, :as => :add_mobile_option_point
  match '/mobile/options/:option_id/points/new/:type' => "mobile/mobile#new_point", :via => :get, :module => :mobile, :as => :new_mobile_option_point
  match '/mobile/options/:option_id/points/:point_id' => "mobile/mobile#point_details", :via => :get, :module => :mobile, :as => :show_mobile_option_point
  match '/mobile/options/:option_id/positions/final' => "mobile/mobile#position_final", :via => :get, :module => :mobile, :as => :mobile_option_final_position
  match '/mobile/options/:option_id/summary' => "mobile/mobile#summary", :via => :get, :module => :mobile, :as => :mobile_option_summary
  match '/mobile/options/:option_id/summary/:stance_bucket' => "mobile/mobile#segment", :via => :get, :module => :mobile, :as => :mobile_option_segment
  match '/mobile/options/:option_id/summary/:stance_bucket/:point_type' => "mobile/mobile#segment_list", :via => :get, :module => :mobile, :as => :mobile_option_segment_list

  # Mobile Navigation
  match '/mobile/options/:option_id/navigate' => "mobile/navigation#navigate", :module => :mobile, :via => :post, :as => :mobile_navigate
end
