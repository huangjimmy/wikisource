defmodule WikisourceWeb.Schema.BookTypes do
  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers, only: [dataloader: 2, dataloader: 3]

  alias WikisourceWeb.{DataSource, Resolvers}

  object :book do
    field :id, :id
    field :html, :string
    field :info, :string
    field :name, :string
    field :preface, :string
    field :text, :string
    field :url, :string

    field :info_html, :string
    field :preface_html, :string

    field :book, :book, resolve: dataloader(DataSource, :book)
    field :chapters, list_of(:book) do
      arg(:offset, non_null(:integer))
      arg(:first, non_null(:integer))
      resolve(dataloader(DataSource, :chapters, args: %{chapters: true}))
      # resolve(&Resolvers.BookResolver.chapters/3)
    end
  end

  object :books do
    field :query, :string
    field :offset, :integer
    field :first, :integer
    field :total, :integer
    field :books, list_of(:book)
  end

  object :book_queries do
    @desc "Get a specific book"
    field :book, :book do
      arg(:id, non_null(:id))
      resolve(&Resolvers.BookResolver.get/3)
    end

    @desc "Get a list of books who belongs to no parent"
    field :list_book, :books do
      arg(:offset, :integer)
      arg(:first, :integer)
      arg(:parent, :integer)
      resolve(&Resolvers.BookResolver.list/3)
    end

    @desc "Get a list of books by full text search"
    field :search_books, :books do
      arg(:query, non_null(:string))
      arg(:offset, :integer)
      arg(:first, :integer)
      resolve(&Resolvers.BookResolver.search/3)
    end

    @desc "search books by matching fields"
    field :filter_books, :books do
      arg(:name, :string)
      arg(:info, :string)
      arg(:preface, :string)
      arg(:text, :string)
      arg(:offset, :integer)
      arg(:first, :integer)
      resolve(&Resolvers.BookResolver.filter/3)
    end
  end
end
