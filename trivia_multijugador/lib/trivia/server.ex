defmodule TriviaMultijugador.Server do
  use GenServer
  require Logger

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{next_game_id: 1, active_games: %{}}, name: __MODULE__)
  end

  def connect(username, password) do
    GenServer.call(__MODULE__, {:connect, username, password})
  end

  def create_game(username, topic, questions_count, time_per_question) do
    GenServer.call(__MODULE__, {:create_game, username, topic, questions_count, time_per_question})
  end

  def list_active_games() do
    GenServer.call(__MODULE__, :list_active_games)
  end

  def join_game(username, game_id) do
    GenServer.call(__MODULE__, {:join_game, username, game_id})
  end

  def init(state) do
    Logger.info("🚀 Servidor principal iniciado")
    {:ok, state}
  end

  def handle_call({:connect, username, password}, _from, state) do
    Logger.info("🔐 Intento de conexión para usuario: #{username}")

    case TriviaMultijugador.UserManager.authenticate(username, password) do
      {:ok, _} ->
        Logger.info("✅ Usuario #{username} autenticado")
        {:reply, {:ok, "Conectado exitosamente"}, state}
      {:error, "Usuario no encontrado"} ->
        Logger.info("📝 Registrando nuevo usuario: #{username}")
        TriviaMultijugador.UserManager.register_user(username, password)
        {:reply, {:ok, "Usuario registrado y conectado"}, state}
      {:error, reason} ->
        # ✅ CORREGIDO: Logger.warning en lugar de Logger.warn
        Logger.warning("❌ Error de autenticación para #{username}: #{reason}")
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:create_game, username, topic, questions_count, time_per_question}, _from, state) do
    game_id = state.next_game_id
    Logger.info("🎮 Solicitando creación de partida #{game_id} por #{username}")

    case TriviaMultijugador.Supervisor.start_game(game_id, topic, questions_count, time_per_question) do
      {:ok, pid} ->
        Logger.info("✅ Partida #{game_id} creada exitosamente con PID: #{inspect(pid)}")

        # PRIMERO agregar al creador como jugador
        case TriviaMultijugador.Game.add_player(game_id, username) do
          :ok ->
            Logger.info("✅ Creador #{username} agregado a partida #{game_id}")

            # LUEGO cargar preguntas
            case TriviaMultijugador.Game.start_game(game_id) do
              {:ok, _message} ->
                Logger.info("✅ Preguntas cargadas para partida #{game_id}")

                # Registrar juego activo
                new_active_games = Map.put(state.active_games, game_id, %{
                  topic: topic,
                  players: [username],
                  created_at: DateTime.utc_now(),
                  max_players: 4,
                  pid: pid
                })

                new_state = %{
                  state |
                  next_game_id: game_id + 1,
                  active_games: new_active_games
                }

                Logger.info("🎯 Partida #{game_id} completamente inicializada")
                {:reply, {:ok, game_id}, new_state}

              {:error, reason} ->
                Logger.error("❌ Error al cargar preguntas para partida #{game_id}: #{reason}")
                # DEVOLVER EL ID AUNQUE FALLE LA CARGA DE PREGUNTAS
                {:reply, {:ok, game_id}, state}
            end

          {:error, reason} ->
            Logger.error("❌ Error al agregar creador a partida #{game_id}: #{reason}")
            # DEVOLVER EL ID AUNQUE FALLE LA AGREGACIÓN DEL CREADOR
            {:reply, {:ok, game_id}, state}
        end

      {:error, reason} ->
        Logger.error("❌ Error al crear partida #{game_id}: #{reason}")
        {:reply, {:error, "No se pudo crear la partida: #{reason}"}, state}
    end
  end

  def handle_call(:list_active_games, _from, state) do
    active_games = Map.filter(state.active_games, fn {game_id, _game_info} ->
      TriviaMultijugador.Supervisor.game_exists?(game_id)
    end)

    Logger.info("📊 Listando #{map_size(active_games)} partidas activas")
    {:reply, active_games, state}
  end

  def handle_call({:join_game, username, game_id}, _from, state) do
    Logger.info("🔄 Intento de unión a partida #{game_id} por #{username}")

    case TriviaMultijugador.Supervisor.game_exists?(game_id) do
      true ->
        Logger.info("✅ Partida #{game_id} encontrada y activa")

        case TriviaMultijugador.Game.add_player(game_id, username) do
          :ok ->
            Logger.info("✅ #{username} unido exitosamente a partida #{game_id}")

            game_info = Map.get(state.active_games, game_id)
            if game_info do
              updated_players = [username | game_info.players]
              updated_game_info = Map.put(game_info, :players, updated_players)
              new_active_games = Map.put(state.active_games, game_id, updated_game_info)
              {:reply, :ok, %{state | active_games: new_active_games}}
            else
              new_active_games = Map.put(state.active_games, game_id, %{
                topic: "desconocido",
                players: [username],
                created_at: DateTime.utc_now(),
                max_players: 4
              })
              {:reply, :ok, %{state | active_games: new_active_games}}
            end

          {:error, reason} ->
            # ✅ CORREGIDO: Logger.warning en lugar de Logger.warn
            Logger.warning("❌ Error al unir #{username} a partida #{game_id}: #{reason}")
            {:reply, {:error, reason}, state}
        end

      false ->
        # ✅ CORREGIDO: Logger.warning en lugar de Logger.warn
        Logger.warning("❌ Partida #{game_id} no encontrada o inactiva")
        new_active_games = Map.delete(state.active_games, game_id)
        {:reply, {:error, "Partida no encontrada o ya terminó"}, %{state | active_games: new_active_games}}
    end
  end
end
