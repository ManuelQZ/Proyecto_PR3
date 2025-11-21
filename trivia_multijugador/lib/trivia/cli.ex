defmodule TriviaMultijugador.CLI do
  def start do
    IO.puts("🎮 TRIVIA MULTIJUGADOR")
    IO.puts("💡 Si tienes problemas, cierra todas las terminales y vuelve a abrir")
    main_loop(nil, nil)
  end

  defp main_loop(username, game_pid) do
    if game_pid do
      game_loop(username, game_pid)
    else
      display_main_menu(username)
      input = IO.gets("Opción: ") |> String.trim()

      case {input, username} do
        {"1", nil} ->
          login_flow()
        {"1", username} ->
          create_game_flow(username)
        {"2", username} when username != nil ->
          join_game_flow(username)
        {"3", username} when username != nil ->
          list_games_flow(username)
        {"4", _} ->
          IO.puts("¡Hasta pronto!")
          System.halt(0)
        {"2", nil} ->
          IO.puts("¡Hasta pronto!")
          System.halt(0)
        _ ->
          IO.puts("Opción inválida")
          main_loop(username, game_pid)
      end
    end
  end

  defp game_loop(username, game_pid) do
    input = IO.gets("") |> String.trim()

    case String.upcase(input) do
      "A" -> send_answer(game_pid, username, "A")
      "B" -> send_answer(game_pid, username, "B")
      "C" -> send_answer(game_pid, username, "C")
      "D" -> send_answer(game_pid, username, "D")
      "INICIAR" ->
        start_existing_game(game_pid)
      "SALIR" ->
        IO.puts("Abandonando partida...")
        main_loop(username, nil)
      "ESTADO" ->
        show_game_status(game_pid)
      "JUGADORES" ->
        show_players(game_pid)
      "CERRAR" ->
        close_game(game_pid, username)
      "TIEMPO" ->
        show_time_remaining()
      "DEBUG" ->
        show_debug_info(game_pid)
      _ ->
        IO.puts("Comando inválido. Usa: A, B, C, D, INICIAR, ESTADO, JUGADORES, TIEMPO, CERRAR, DEBUG o SALIR")
    end

    game_loop(username, game_pid)
  end

  defp send_answer(game_pid, username, answer) do
    TriviaMultijugador.Game.submit_answer(game_pid, username, answer)
  end

  defp start_existing_game(game_pid) do
    case TriviaMultijugador.Game.begin_game(game_pid) do
      :ok ->
        IO.puts("🎮 Iniciando partida #{game_pid}...")
      {:error, reason} ->
        IO.puts("❌ #{reason}")
    end
  end

  defp close_game(game_pid, username) do
    case TriviaMultijugador.Game.close_game(game_pid) do
      :ok ->
        IO.puts("🔒 Partida #{game_pid} cerrada por #{username}")
        main_loop(username, nil)
      {:error, reason} ->
        IO.puts("❌ Error al cerrar partida: #{reason}")
    end
  end

  defp show_time_remaining() do
    IO.puts("💡 La partida comenzará cuando el creador use 'INICIAR'")
    IO.puts("🎯 O cuando se unan 4 jugadores")
  end

  defp show_debug_info(game_pid) do
    IO.puts("\n🐛 INFORMACIÓN DE DEPURACIÓN:")
    IO.puts("   ID de partida: #{game_pid}")
    IO.puts("   Proceso vivo: #{TriviaMultijugador.Supervisor.game_exists?(game_pid)}")

    case TriviaMultijugador.Game.get_state(game_pid) do
      {:ok, state} ->
        IO.puts("   Estado interno de la partida:")
        IO.puts("     - Tema: #{state.topic}")
        IO.puts("     - Jugadores: #{map_size(state.players)}")
        IO.puts("     - Preguntas cargadas: #{length(state.questions)}")
        IO.puts("     - Iniciada: #{state.started}")
        IO.puts("     - Terminada: #{state.finished}")
      {:error, reason} ->
        IO.puts("   Error al obtener estado: #{reason}")
    end
    IO.puts("")
  end

  defp show_game_status(game_pid) do
    case TriviaMultijugador.Game.get_state(game_pid) do
      {:ok, state} ->
        IO.puts("\n📊 ESTADO DE LA PARTIDA #{game_pid}:")
        IO.puts("   Tema: #{state.topic}")
        IO.puts("   Jugadores: #{map_size(state.players)}/#{state.max_players}")
        IO.puts("   Creador: #{state.creator || "No asignado"}")
        IO.puts("   Preguntas cargadas: #{length(state.questions)}")
        IO.puts("   Estado: #{cond do
          !state.keep_alive -> "Cerrada"
          state.finished -> "Terminada"
          state.started -> "En curso"
          true -> "Esperando para iniciar"
        end}")
        if state.started and !state.finished do
          IO.puts("   Pregunta actual: #{state.current_question_index + 1}/#{state.questions_count}")
        end
        IO.puts("")
      {:error, reason} ->
        IO.puts("❌ #{reason}")
    end
  end

  defp show_players(game_pid) do
    case TriviaMultijugador.Game.get_state(game_pid) do
      {:ok, state} ->
        IO.puts("\n👥 JUGADORES EN PARTIDA #{game_pid}:")
        if map_size(state.players) == 0 do
          IO.puts("   No hay jugadores aún")
        else
          Enum.each(state.players, fn {username, player} ->
            creator_indicator = if username == state.creator, do: " 👑", else: ""
            IO.puts("   👤 #{username}#{creator_indicator} - Puntos: #{player.score}")
          end)
        end
        IO.puts("   📊 #{map_size(state.players)}/#{state.max_players} jugadores")
        IO.puts("")
      {:error, reason} ->
        IO.puts("❌ #{reason}")
    end
  end

  defp display_main_menu(nil) do
    IO.puts("\n" <> String.duplicate("=", 40))
    IO.puts("1. Conectar/Registrar")
    IO.puts("2. Salir")
    IO.puts(String.duplicate("=", 40))
  end

  defp display_main_menu(username) do
    IO.puts("\n" <> String.duplicate("=", 40))
    IO.puts("Usuario: #{username}")
    IO.puts("1. Crear partida")
    IO.puts("2. Unirse a partida existente")
    IO.puts("3. Listar partidas activas")
    IO.puts("4. Salir")
    IO.puts(String.duplicate("=", 40))
  end

  defp login_flow do
    username = IO.gets("Usuario: ") |> String.trim()
    password = IO.gets("Contraseña: ") |> String.trim()

    case TriviaMultijugador.Server.connect(username, password) do
      {:ok, message} ->
        IO.puts("✅ #{message}")
        main_loop(username, nil)
      {:error, reason} ->
        IO.puts("❌ #{reason}")
        main_loop(nil, nil)
    end
  end

  defp create_game_flow(username) do
    topic_input = IO.gets("Tema (ciencia/historia): ") |> String.trim()

    topic = String.downcase(topic_input)

    if topic not in ["ciencia", "historia"] do
      IO.puts("❌ Tema inválido. Solo se permite 'ciencia' o 'historia'")
      main_loop(username, nil)
    else
      IO.puts("🔄 Creando partida...")

      case TriviaMultijugador.Server.create_game(username, topic, 3, 15) do
        {:ok, game_id} ->
          IO.puts("")
          IO.puts("🎉 ¡PARTIDA CREADA EXITOSAMENTE!")
          IO.puts("========================================")
          IO.puts("   🆔 ID DE PARTIDA: #{game_id}")
          IO.puts("   📝 Tema: #{topic}")
          IO.puts("   👤 Creador: #{username}")
          IO.puts("   👥 Jugadores: 1/4")
          IO.puts("========================================")
          IO.puts("")
          IO.puts("💡 **INSTRUCCIONES IMPORTANTES:**")
          IO.puts("   1. Comparte este ID con otros jugadores: #{game_id}")
          IO.puts("   2. Usa 'ESTADO' para ver jugadores conectados")
          IO.puts("   3. Usa 'INICIAR' para comenzar cuando estén todos")
          IO.puts("   4. La partida comenzará automáticamente con 4 jugadores")
          IO.puts("")

          show_game_commands()

          main_loop(username, game_id)

        {:error, reason} ->
          IO.puts("")
          IO.puts("❌ ERROR AL CREAR PARTIDA: #{reason}")
          IO.puts("💡 Soluciones:")
          IO.puts("   - Intenta crear la partida nuevamente")
          IO.puts("   - Reinicia la aplicación si el problema persiste")
          IO.puts("")
          main_loop(username, nil)
      end
    end
  end

  defp join_game_flow(username) do
    IO.puts("")
    IO.puts("🎯 UNIRSE A PARTIDA EXISTENTE")
    IO.puts("💡 Pide el ID de partida al creador")
    game_id_str = IO.gets("ID de partida a unirse: ") |> String.trim()

    case Integer.parse(game_id_str) do
      {game_id, ""} ->
        IO.puts("🔄 Conectando a partida #{game_id}...")

        case TriviaMultijugador.Server.join_game(username, game_id) do
          :ok ->
            IO.puts("")
            IO.puts("✅ ¡TE UNISTE A LA PARTIDA #{game_id}!")
            IO.puts("💡 Comandos disponibles:")
            IO.puts("   - Usa 'ESTADO' para ver información de la partida")
            IO.puts("   - Usa 'JUGADORES' para ver quiénes están conectados")
            IO.puts("   - Espera a que el creador inicie la partida")
            IO.puts("")

            show_game_commands()

            main_loop(username, game_id)

          {:error, reason} ->
            IO.puts("")
            IO.puts("❌ NO SE PUDO UNIR: #{reason}")
            IO.puts("💡 Posibles soluciones:")
            IO.puts("   - Verifica que el ID #{game_id} sea correcto")
            IO.puts("   - La partida puede estar llena o haber terminado")
            IO.puts("   - Usa 'Listar partidas activas' para ver partidas disponibles")
            IO.puts("")
            main_loop(username, nil)
        end

      _ ->
        IO.puts("❌ ID de partida inválido. Debe ser un número (ej: 1, 2, 3).")
        main_loop(username, nil)
    end
  end

  defp list_games_flow(username) do
    IO.puts("🔄 Buscando partidas activas...")

    case TriviaMultijugador.Server.list_active_games() do
      active_games when map_size(active_games) == 0 ->
        IO.puts("📭 No hay partidas activas en este momento")
        IO.puts("💡 Crea una nueva partida con la opción 1")
        main_loop(username, nil)

      active_games ->
        IO.puts("\n🎮 PARTIDAS ACTIVAS:")
        Enum.each(active_games, fn {game_id, game_info} ->
          IO.puts("   ID: #{game_id} - Tema: #{game_info.topic}")
          IO.puts("   Jugadores: #{Enum.join(game_info.players, ", ")}")
          IO.puts("   Progreso: #{length(game_info.players)}/#{game_info.max_players} jugadores")
          IO.puts("   " <> String.duplicate("-", 30))
        end)
        IO.puts("💡 Usa la opción 2 para unirte a una partida (ingresa el ID)")
        main_loop(username, nil)
    end
  end

  defp show_game_commands do
    IO.puts("\n🎮 COMANDOS DISPONIBLES:")
    IO.puts("   A, B, C, D - Responder pregunta")
    IO.puts("   INICIAR     - Comenzar la partida manualmente")
    IO.puts("   ESTADO      - Ver estado de la partida")
    IO.puts("   JUGADORES   - Ver jugadores conectados")
    IO.puts("   TIEMPO      - Ver información de inicio")
    IO.puts("   DEBUG       - Información técnica de la partida")
    IO.puts("   CERRAR      - Cerrar partida (solo creador)")
    IO.puts("   SALIR       - Abandonar partida")
    IO.puts("")
  end
end
