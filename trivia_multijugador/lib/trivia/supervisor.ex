defmodule TriviaMultijugador.Supervisor do
  use DynamicSupervisor

  def start_link(_opts) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_game(game_id, topic, questions_count, time_per_question) do
    spec = {TriviaMultijugador.Game, %{
      id: game_id,
      topic: topic,
      questions_count: questions_count,
      time_per_question: time_per_question
    }}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end
end
