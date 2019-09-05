defmodule Wikisource.Repo.Migrations.AddBookInfoPrefaceHtmlField do
  use Ecto.Migration

  def change do
    alter table(:books) do
      add :info_html, :text
      add :preface_html, :text
    end
  end
end
