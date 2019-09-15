defmodule Wikisource do
  @moduledoc """
  Wikisource keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  def elastic do
    quote do
      def elastic_url do
        Application.get_env(:elastix, :url, "http://localhost:9200")
      end
    end
  end

  @doc """
  When used, dispatch to the appropriate components/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
