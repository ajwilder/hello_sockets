defmodule Camp1Web.Router do
  use Camp1Web, :router

  import Camp1Web.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :guest do
    plug Camp1Web.GuestToken
  end

  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: Camp1Web.Telemetry
    end
  end

  ## Authentication routes

  scope "/", Camp1Web do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
    get "/users/log_in", UserSessionController, :new
    post "/users/log_in", UserSessionController, :create
    get "/users/reset_password", UserResetPasswordController, :new
    post "/users/reset_password", UserResetPasswordController, :create
    get "/users/reset_password/:token", UserResetPasswordController, :edit
    put "/users/reset_password/:token", UserResetPasswordController, :update
  end

  scope "/", Camp1Web do
    pipe_through [:browser, :require_authenticated_user]
    get "/home", UserController, :user_home
    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email
  end

  scope "/", Camp1Web do
    pipe_through [:browser]
    delete "/users/log_out", UserSessionController, :delete
    get "/users/confirm", UserConfirmationController, :new
    post "/users/confirm", UserConfirmationController, :create
    get "/users/confirm/:token", UserConfirmationController, :confirm
  end

  # Guest Home Routes
  scope "/", Camp1Web do
    pipe_through [:browser, :redirect_if_user_is_authenticated, :guest]
    get "/", GuestController, :guest_home
  end

  # GUEST ROUTES
  scope "/g/", Camp1Web do
    pipe_through [:browser, :redirect_if_user_is_authenticated, :guest]
    get "/results", SurveyController, :guest_results # Dev only
    get "/survey", SurveyController, :guest_survey
  end

  # LOGGED IN APP ROUTES
  scope "/", Camp1Web do
    pipe_through [:browser, :require_authenticated_user]
    post "/camp/:id/create-post", CommentController, :create_post
    post "/camp/:id/create-image", CommentController, :create_image
    post "/camp/:id/create-document", CommentController, :create_document
    get "/camp/:id", CampController, :user_explore_camp
  end

  # Camp ROUTES
  scope "/", Camp1Web do
    pipe_through [:browser]
    get "/g/camp/:id", CampController, :guest_explore_camp
  end

  # IMAGE ROUTES
  scope "/", Camp1Web do
    pipe_through [:browser]
    get "/image/:id/thumbnail", ImageController, :thumbnail
    get "/image/:id", ImageController, :show
    get "/document/:id", DocumentController, :show
    get "/document/:id/thumbnail", DocumentController, :thumbnail
  end

  # DEV ROUTES
  scope "/", Camp1Web do
    pipe_through [:browser]
    resources "/camp", CampController
    get "/camp/parent/:id", CampController, :camps_by_parent_id
  end
end
