defmodule TriviaMultijugador.Application do
  use Application

  def start(_type, _args) do
    children = [
      TriviaMultijugador.Supervisor,
      TriviaMultijugador.UserManager,
      TriviaMultijugador.QuestionBank,
      TriviaMultijugador.Server
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
