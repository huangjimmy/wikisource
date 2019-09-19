import Config

config :elastix,
  url: System.get_env("WIKISOURCE_ELASTIC_URL", "http://elasticsearc:9200")
