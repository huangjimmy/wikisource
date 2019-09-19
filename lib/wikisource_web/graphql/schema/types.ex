defmodule WikisourceWeb.Schema.BookTypes do
  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers, only: [dataloader: 2, dataloader: 3]

  alias WikisourceWeb.{DataSource, Resolvers}

  object :session do
    field :session_id, :string
  end

  object :session_mutations do
    @desc "create a new session"
    field :create_session, :session do
      arg(:device_id, non_null(:string))
      arg(:device_type, non_null(:string))
      arg(:device_desc, non_null(:string))
      resolve(&Resolvers.SessionResolver.create/3)
    end

    @desc "invalidate session"
    field :delete_session, :session do
      arg(:session_id, non_null(:string))
      resolve(&Resolvers.SessionResolver.delete/3)
    end
  end

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

    @desc "highlighted text in info field when there are some search matches in info field"
    field :info_highlight, :string
    @desc "highlighted text in name field when there are some search matches in name field"
    field :name_highlight, :string
    @desc "highlighted text in preface field when there are some search matches in preface field"
    field :preface_highlight, :string
    @desc "highlighted text in text field when there are some search matches in text field"
    field :text_highlight, :string

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
