defmodule WikisourceWeb.Schema do
  use Absinthe.Schema

  alias WikisourceWeb.{Data, Resolvers}

  alias WikisourceWeb.Data

  import_types(Absinthe.Type.Custom)
  import_types(WikisourceWeb.Schema.BookTypes)

  query do
    import_fields(:book_queries)
  end

end
