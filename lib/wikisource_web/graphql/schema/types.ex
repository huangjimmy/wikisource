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
    field :chapters, list_of(:book), resolve: dataloader(DataSource, :chapters, [])
  end

  object :books do
    field :query, :string
    field :from, :integer
    field :size, :integer
    field :total, :integer
    field :books, list_of(:book)
  end

  object :book_queries do
    @desc "Get a specific book"
    field :book, :book do
      arg(:id, non_null(:id))
      resolve(&Resolvers.BookResolver.get/3)
    end

    @desc "Get a list of books by fuzzy search"
    field :search_books, :books do
      arg(:query, non_null(:string))
      arg(:from, :integer)
      arg(:size, :integer)
      resolve(&Resolvers.BookResolver.search/3)
    end

    @desc "Get a list of books by matching fields"
    field :filter_books, :books do
      arg(:name, :string)
      arg(:info, :string)
      arg(:preface, :string)
      arg(:text, :string)
      arg(:from, :integer)
      arg(:size, :integer)
      resolve(&Resolvers.BookResolver.filter/3)
    end
  end
end
