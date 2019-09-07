defmodule WikisourceWeb.Schema do
  use Absinthe.Schema

  alias WikisourceWeb.DataSource

  import_types(Absinthe.Type.Custom)
  import_types(WikisourceWeb.Schema.BookTypes)

  query do
    import_fields(:book_queries)
  end

  def context(ctx) do
    loader =
      Dataloader.new()
      |> Dataloader.add_source(DataSource, DataSource.data())

    Map.put(ctx, :loader, loader)
  end

  def plugins do
    [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
  end

end
