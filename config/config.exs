use Mix.Config

config :logger,
  level: :info,
  utc_log: false,
  compile_time_purge_level: :info,
  backends: [:console]
