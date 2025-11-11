# mix.exs
defmodule TriviaMultijugador.MixProject do
  use Mix.Project

  def project do
    [
      app: :trivia_multijugador,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {TriviaMultijugador.Application, []}
    ]
  end

  defp deps do
    []  # Sin dependencias externas por ahora
  end
end
