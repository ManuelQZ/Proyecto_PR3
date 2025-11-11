defmodule TriviaMultijugador.Server do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{next_game_id: 1}, name: __MODULE__)
  end

  def connect(username, password) do
    GenServer.call(__MODULE__, {:connect, username, password})
  end

  def create_game(username, topic, questions_count, time_per_question) do
    GenServer.call(__MODULE__, {:create_game, username, topic, questions_count, time_per_question})
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call({:connect, username, password}, _from, state) do
    case TriviaMultijugador.UserManager.authenticate(username, password) do
      {:ok, _} ->
        {:reply, {:ok, "Conectado exitosamente"}, state}
      {:error, "Usuario no encontrado"} ->
        TriviaMultijugador.UserManager.register_user(username, password)
        {:reply, {:ok, "Usuario registrado y conectado"}, state}
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:create_game, username, topic, questions_count, time_per_question}, _from, state) do
    game_id = state.next_game_id

    case TriviaMultijugador.Supervisor.start_game(game_id, topic, questions_count, time_per_question) do
      {:ok, _pid} ->
        # Auto-unir al creador
        TriviaMultijugador.Game.add_player(game_id, username)
        new_state = Map.put(state, :next_game_id, game_id + 1)
        {:reply, {:ok, game_id}, new_state}
      _error ->
        {:reply, {:error, "No se pudo crear la partida"}, state}
    end
  end
end
