defmodule PhxNewYosu.MixProject do
  use Mix.Project

  def project do
    [
      app: :phx_new_yosu,
      version: "0.1.0",
      elixir: "~> 1.18",
      package: package(),
      description: description(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  defp package do
    [
      name: :phx_new_yosu,
      maintainers: ["yosu"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/yosu/phx_new_yosu"}
    ]
  end

  defp description do
    "A wrapper for mix phx.new with better defaults. Use short UUIDs and utc_datetime_usec by default."
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phx_new, "~> 1.7", only: :dev, runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
