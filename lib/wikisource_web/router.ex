defmodule WikisourceWeb.Router do
  use WikisourceWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug Phoenix.LiveView.Flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug WikisourceWeb.Context
    plug :accepts, ["json"]
  end

  scope "/api" do
    pipe_through :api
    forward "/", Absinthe.Plug,
      schema: WikisourceWeb.Schema
  end

  scope "/iql" do
    pipe_through :api
    forward "/", Absinthe.Plug.GraphiQL,
      schema: WikisourceWeb.Schema
  end

  scope "/", WikisourceWeb do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    post "/search", PageController, :search
    get "/search", PageController, :search
    live "/app", HomeView
  end

  scope "/wiki", WikisourceWeb do
    pipe_through [:browser]
    get "/", WikiController, :index
    get "/:book", WikiController, :book
    get "/:book/:volume", WikiController, :page
    get "/:book/:volume/:chapter", WikiController, :page
    get "/:book/:volume/:chapter/:page", WikiController, :page
  end

  # Other scopes may use custom stacks.
  # scope "/api", WikisourceWeb do
  #   pipe_through :api
  # end
end
