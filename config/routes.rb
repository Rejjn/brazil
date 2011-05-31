Brazil::Application.routes.draw do
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => "welcome#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
  
  resources :db_instances do
    member do
      get :delete
    end
  end

  resources :apps do
    member do
      get :delete
    end
    
    resources :activities do
      collection do
        get :base_versions
      end
      member do
        get :delete
        post :execute
      end
      
      resources :changes do
        member do
          get :delete
          post :execute
        end
      end

      resources :versions do
        member do
          get :delete
          post :test_rollback
          post :test_update
          post :upload
          post :deployed
        end
      end
    end
  end

  match 'deploy/:app/:schema/:db_instance/wipe' => 'deploy#wipe', :as => :wipe_instance_schema_app_deploy, :via => 'post'
  match 'deploy/:app/:schema/:db_instance/rollback' => 'deploy#rollback', :as => :rollback_instance_schema_app_deploy, :via => 'post'
  match 'deploy/:app/:schema/:db_instance/update' => 'deploy#update', :as => :update_instance_schema_app_deploy, :via => 'post'
  match 'deploy/:app/:schema/:db_instance/credentials' => 'deploy#wipe_credentials', :as => :credentials_instance_schema_app_deploy
  match 'deploy/:app/:schema/:db_instance' => 'deploy#show_instance', :as => :instance_schema_app_deploy
  match 'deploy/:app/:schema' => 'deploy#show_schema', :as => :schema_app_deploy
  match 'deploy/:app' => 'deploy#show_app', :as => :app_deploy
  match 'deploy' => 'deploy#index', :as => :deploy
  match 'repo_browser' => 'repo_browser#index', :as => :repo_browser
  match ':controller/:action' => '#index'
  match '/' => 'apps#index'

end
