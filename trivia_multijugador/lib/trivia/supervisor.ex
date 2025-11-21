defmodule TriviaMultijugador.Supervisor do
  use DynamicSupervisor
  require Logger

  def start_link(_opts) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_game(game_id, topic, questions_count, time_per_question) do
    case :global.whereis_name({:game, game_id}) do
      :undefined ->
        spec = {TriviaMultijugador.Game, %{
          id: game_id,
          topic: topic,
          questions_count: questions_count,
          time_per_question: time_per_question
        }}

        Logger.info("🔄 Intentando crear partida #{game_id}...")

        case DynamicSupervisor.start_child(__MODULE__, spec) do
          {:ok, pid} ->
            Logger.info("✅ Partida #{game_id} creada con PID: #{inspect(pid)}")

            :timer.sleep(500)

            case wait_for_game_registration(game_id, pid, 5) do
              {:ok, _} ->
                Logger.info("✅ Partida #{game_id} registrada globalmente")
                {:ok, pid}
              {:error, reason} ->
                Logger.error("❌ Partida #{game_id} no se registró: #{reason}")
                {:ok, pid}
            end

          {:error, {:already_started, pid}} ->
            # ✅ CORREGIDO: Logger.warning en lugar de Logger.warn
            Logger.warning("⚠️ Partida #{game_id} ya estaba iniciada con PID: #{inspect(pid)}")
            {:ok, pid}

          error ->
            Logger.error("❌ Error al crear partida #{game_id}: #{inspect(error)}")
            error
        end

      pid when is_pid(pid) ->
        # ✅ CORREGIDO: Logger.warning en lugar de Logger.warn
        Logger.warning("⚠️ Ya existe una partida con ID #{game_id}")
        {:ok, pid}
    end
  end

  defp wait_for_game_registration(game_id, expected_pid, retries) when retries > 0 do
    case :global.whereis_name({:game, game_id}) do
      ^expected_pid ->
        {:ok, expected_pid}
      :undefined ->
        Logger.info("⏳ Esperando registro de partida #{game_id}... (intentos restantes: #{retries})")
        :timer.sleep(300)
        wait_for_game_registration(game_id, expected_pid, retries - 1)
      other_pid ->
        {:error, "Registro incorrecto. Esperado: #{inspect(expected_pid)}, Obtenido: #{inspect(other_pid)}"}
    end
  end

  defp wait_for_game_registration(_game_id, _expected_pid, 0) do
    {:error, "Timeout en registro global"}
  end

  def game_exists?(game_id) do
    case :global.whereis_name({:game, game_id}) do
      :undefined ->
        false
      pid ->
        Process.alive?(pid)
    end
  end

  def get_game_pid(game_id) do
    case :global.whereis_name({:game, game_id}) do
      :undefined -> {:error, "Partida no encontrada"}
      pid -> {:ok, pid}
    end
  end
end
