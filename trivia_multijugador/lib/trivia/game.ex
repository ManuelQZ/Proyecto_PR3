defmodule TriviaMultijugador.Game do
  use GenServer
  require Logger

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
      finished: false,
      timer_ref: nil,
      answers: %{},
      current_question_index: 0,
      keep_alive: true,
      creator: nil,
      max_players: 4
    }

    via_tuple = {:via, :global, {:game, game_id}}

    case GenServer.start_link(__MODULE__, initial_state, name: via_tuple) do
      {:ok, pid} ->
        Logger.info("🎮 Partida #{game_id} iniciada correctamente con PID: #{inspect(pid)}")
        {:ok, pid}
      error ->
        Logger.error("❌ Error al iniciar partida #{game_id}: #{inspect(error)}")
        error
    end
  end

  defp via_tuple(game_id) do
    {:via, :global, {:game, game_id}}
  end

  def add_player(game_id, username) do
    case GenServer.call(via_tuple(game_id), {:add_player, username}, 5000) do
      {:error, :timeout} ->
        {:error, "La partida no está respondiendo"}
      result ->
        result
    end
  end

  def start_game(game_id) do
    case GenServer.call(via_tuple(game_id), :start_game, 5000) do
      {:error, :timeout} ->
        {:error, "La partida no está respondiendo"}
      result ->
        result
    end
  end

  def submit_answer(game_id, username, answer) do
    GenServer.cast(via_tuple(game_id), {:submit_answer, username, answer})
  end

  def get_state(game_id) do
    case GenServer.call(via_tuple(game_id), :get_state, 5000) do
      {:error, :timeout} ->
        {:error, "La partida no está respondiendo"}
      result ->
        result
    end
  end

  def begin_game(game_id) do
    case GenServer.call(via_tuple(game_id), :begin_game, 5000) do
      {:error, :timeout} ->
        {:error, "La partida no está respondiendo"}
      result ->
        result
    end
  end

  def close_game(game_id) do
    case GenServer.call(via_tuple(game_id), :close_game, 5000) do
      {:error, :timeout} ->
        {:error, "La partida no está respondiendo"}
      result ->
        result
    end
  end

  # === CALLBACKS ===
  def init(state) do
    Logger.info("🎮 Partida #{state.id} inicializada - Esperando jugadores...")
    {:ok, state}
  end

  def terminate(reason, state) do
    Logger.info("🎮 Partida #{state.id} terminada: #{inspect(reason)}")
    :ok
  end

  def handle_call({:add_player, username}, _from, state) do
    cond do
      !state.keep_alive ->
        {:reply, {:error, "La partida ya no está disponible"}, state}
      state.started ->
        {:reply, {:error, "La partida ya comenzó"}, state}
      state.finished ->
        {:reply, {:error, "La partida ya terminó"}, state}
      map_size(state.players) >= state.max_players ->
        {:reply, {:error, "Partida llena"}, state}
      true ->
        # Primer jugador es el creador
        new_state = if map_size(state.players) == 0 do
          %{state | creator: username}
        else
          state
        end

        new_players = Map.put(new_state.players, username, %{score: 0, answered: false})

        final_state = %{new_state | players: new_players}

        IO.puts("🎮 #{username} se unió a la partida #{state.id}")
        IO.puts("👥 Jugadores en partida: #{Enum.join(Map.keys(new_players), ", ")}")
        IO.puts("📊 #{map_size(new_players)}/#{state.max_players} jugadores")

        # Iniciar automáticamente si se alcanzó el máximo
        if map_size(new_players) == state.max_players do
          IO.puts("🎯 ¡Partida completa! Iniciando automáticamente...")
          Process.send_after(self(), :begin_game_now, 2000)
          {:reply, :ok, final_state}
        else
          {:reply, :ok, final_state}
        end
    end
  end

  def handle_call(:start_game, _from, state) do
    questions = TriviaMultijugador.QuestionBank.get_questions(state.topic, state.questions_count)

    if Enum.empty?(questions) do
      {:reply, {:error, "No hay preguntas disponibles para el tema: #{state.topic}"}, state}
    else
      {:reply, {:ok, "Partida lista con #{length(questions)} preguntas"}, %{state | questions: questions}}
    end
  end

  def handle_call(:begin_game, _from, state) do
    cond do
      !state.keep_alive ->
        {:reply, {:error, "La partida ya no está disponible"}, state}
      state.started ->
        {:reply, {:error, "La partida ya comenzó"}, state}
      state.finished ->
        {:reply, {:error, "La partida ya terminó"}, state}
      map_size(state.players) < 1 ->
        {:reply, {:error, "Se necesitan jugadores para comenzar"}, state}
      Enum.empty?(state.questions) ->
        {:reply, {:error, "No hay preguntas cargadas"}, state}
      true ->
        IO.puts("🎮 Partida #{state.id} iniciada! Tema: #{state.topic}")
        IO.puts("👥 Jugadores: #{Enum.join(Map.keys(state.players), ", ")}")
        IO.puts("📝 Total de preguntas: #{length(state.questions)}")

        Process.send_after(self(), :next_question, 2000)
        {:reply, :ok, %{state | started: true}}
    end
  end

  def handle_call(:get_state, _from, state) do
    {:reply, {:ok, state}, state}
  end

  def handle_call(:close_game, _from, state) do
    {:stop, :normal, :ok, state}
  end

  def handle_cast({:submit_answer, username, answer}, state) do
    if state.current_question && !state.finished && state.started && state.keep_alive do
      correct_answer = state.current_question.correct_answer
      is_correct = String.upcase(answer) == correct_answer

      points = if is_correct, do: 10, else: 0

      player = Map.get(state.players, username)
      if player && !player.answered do
        updated_players = Map.update!(state.players, username, fn player ->
          %{player |
            score: player.score + points,
            answered: true
          }
        end)

        new_answers = Map.put(state.answers, username, %{
          answer: answer,
          correct: is_correct,
          points: points
        })

        IO.puts("📝 #{username} respondió: #{answer} #{if is_correct, do: "✅", else: "❌"}")

        {:noreply, %{state | players: updated_players, answers: new_answers}}
      else
        IO.puts("⚠️ #{username} ya respondió esta pregunta o no existe")
        {:noreply, state}
      end
    else
      {:noreply, state}
    end
  end

  # Manejar inicio inmediato (para máximo de jugadores)
  def handle_info(:begin_game_now, state) do
    if !state.started && !state.finished do
      Process.send_after(self(), :next_question, 2000)
      {:noreply, %{state | started: true}}
    else
      {:noreply, state}
    end
  end

  def handle_info(:next_question, state) do
    if state.timer_ref do
      Process.cancel_timer(state.timer_ref)
    end

    case Enum.at(state.questions, state.current_question_index) do
      nil ->
        IO.puts("🏆 Partida #{state.id} terminada!")
        show_final_scores(state.players)
        {:noreply, %{state | finished: true}}

      question ->
        show_question(state.id, question, state.current_question_index + 1, length(state.questions))

        reset_players = Map.new(state.players, fn {username, player} ->
          {username, %{player | answered: false}}
        end)

        timer_ref = Process.send_after(self(), :timeout, state.time_per_question * 1000)

        {:noreply, %{state |
          current_question: question,
          players: reset_players,
          answers: %{},
          timer_ref: timer_ref
        }}
    end
  end

  def handle_info(:timeout, state) do
    if state.current_question do
      correct_answer = state.current_question.correct_answer
      IO.puts("⏰ Tiempo agotado! Respuesta correcta: #{correct_answer}")

      show_round_results(state.players, state.answers, correct_answer)

      new_index = state.current_question_index + 1

      if new_index >= length(state.questions) do
        IO.puts("🏆 Partida #{state.id} terminada!")
        show_final_scores(state.players)
        {:noreply, %{state | finished: true, current_question_index: new_index}}
      else
        IO.puts("⏳ Siguiente pregunta en 3 segundos...")
        Process.send_after(self(), :next_question, 3000)
        {:noreply, %{state | current_question_index: new_index}}
      end
    else
      {:noreply, state}
    end
  end

  # === FUNCIONES PRIVADAS ===
  defp show_question(game_id, question, question_number, total_questions) do
    IO.puts("\n" <> String.duplicate("=", 50))
    IO.puts("🎯 PARTIDA #{game_id} - Pregunta #{question_number}/#{total_questions}")
    IO.puts("📝 #{question.text}")
    IO.puts("Opciones:")
    Enum.each(question.options, fn {letra, texto} ->
      IO.puts("  #{letra}) #{texto}")
    end)
    IO.puts("⏰ Tienes 15 segundos para responder...")
    IO.puts("💡 Escribe A, B, C o D como respuesta")
    IO.puts(String.duplicate("=", 50))
  end

  defp show_round_results(players, answers, correct_answer) do
    IO.puts("\n📊 RESULTADOS DE LA RONDA:")
    Enum.each(players, fn {username, _player} ->
      case Map.get(answers, username) do
        nil ->
          IO.puts("  #{username}: ❌ No respondió")
        %{answer: answer, correct: true} ->
          IO.puts("  #{username}: ✅ #{answer} (Correcto! +10 puntos)")
        %{answer: answer, correct: false} ->
          IO.puts("  #{username}: ❌ #{answer} (Incorrecto)")
      end
    end)
    IO.puts("  Respuesta correcta: #{correct_answer}")
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
