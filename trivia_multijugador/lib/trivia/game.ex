defmodule TriviaMultijugador.Game do
  use GenServer

  def start_link(%{id: game_id, topic: topic, questions_count: questions_count, time_per_question: time_per_question}) do
    initial_state = %{
      id: game_id,
      topic: topic,
      questions_count: questions_count,
      time_per_question: time_per_question,
      players: %{},
      questions: [],
      current_question: nil,
      started: false,
      finished: false
    }

    GenServer.start_link(__MODULE__, initial_state, name: via_tuple(game_id))
  end

  def add_player(game_id, username) do
    GenServer.call(via_tuple(game_id), {:add_player, username})
  end

  def start_game(game_id) do
    GenServer.call(via_tuple(game_id), :start_game)
  end

  defp via_tuple(game_id) do
    {:via, :global, {:game, game_id}}
  end

  # Server callbacks
  def init(state) do
    {:ok, state}
  end

  def handle_call({:add_player, username}, _from, state) do
    if state.started do
      {:reply, {:error, "La partida ya comenzó"}, state}
    else
      player_count = map_size(state.players)
      if player_count >= 4 do
        {:reply, {:error, "Partida llena"}, state}
      else
        new_players = Map.put(state.players, username, %{score: 0})
        {:reply, :ok, %{state | players: new_players}}
      end
    end
  end

  def handle_call(:start_game, _from, state) do
    questions = TriviaMultijugador.QuestionBank.get_questions(state.topic, state.questions_count)

    if Enum.empty?(questions) do
      {:reply, {:error, "No hay preguntas disponibles"}, state}
    else
      IO.puts("🎮 Partida #{state.id} iniciada! Tema: #{state.topic}")
      # Iniciar primera pregunta después de 2 segundos
      Process.send_after(self(), :next_question, 2000)
      {:reply, :ok, %{state | started: true, questions: questions}}
    end
  end

  def handle_info(:next_question, state) do
    case List.first(state.questions) do
      nil ->
        # No hay más preguntas
        IO.puts("🏆 Partida #{state.id} terminada!")
        show_final_scores(state.players)
        {:noreply, %{state | finished: true}}

      question ->
        show_question(state.id, question)

        # Programar timeout
        Process.send_after(self(), :timeout, state.time_per_question * 1000)

        # Remover la pregunta actual de la lista
        remaining_questions = Enum.drop(state.questions, 1)
        {:noreply, %{state |
          questions: remaining_questions,
          current_question: question
        }}
    end
  end

  def handle_info(:timeout, state) do
    if state.current_question do
      IO.puts("⏰ Tiempo agotado! Respuesta correcta: #{state.current_question.correct_answer}")
      # Pasar a siguiente pregunta después de 3 segundos
      Process.send_after(self(), :next_question, 3000)
    end
    {:noreply, state}
  end

  defp show_question(game_id, question) do
    IO.puts("\n" <> String.duplicate("=", 50))
    IO.puts("🎯 PARTIDA #{game_id}")
    IO.puts("📝 #{question.text}")
    IO.puts("Opciones:")
    Enum.each(question.options, fn {letra, texto} ->
      IO.puts("  #{letra}) #{texto}")
    end)
    IO.puts("⏰ Tienes 15 segundos...")
    IO.puts(String.duplicate("=", 50))
  end

  defp show_final_scores(players) do
    IO.puts("\n" <> String.duplicate("⭐", 20))
    IO.puts("PUNTUACIONES FINALES:")
    players
    |> Enum.sort_by(fn {_name, %{score: score}} -> -score end)
    |> Enum.each(fn {username, %{score: score}} ->
      IO.puts("  #{username}: #{score} puntos")
      TriviaMultijugador.UserManager.update_score(username, score)
    end)
    IO.puts(String.duplicate("⭐", 20))
  end
end
