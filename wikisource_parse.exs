import Ecto.Query
alias Wikisource.{Repo, Page, Book}

query = from(p in Page, where: p.downloaded == 1, select: {p.url, p.id} )
pages = Repo.all(query)

IO.puts("Pages loaded")

total = pages |> Enum.reduce(0, fn {url, p_id}, total ->
  url = String.replace(url, "https://zh.wikisource.org", "")
  html = Repo.one!(from p in Page, where: p.id == ^p_id, select: p.html )

  try do
    case Repo.insert(%Book{ url: url, html: html }) do
     {:ok, _} -> total + 1
     {_, err} -> total
    end
   rescue
    _e -> total
   end
end)

IO.puts(to_string(total) <> " books generated")
