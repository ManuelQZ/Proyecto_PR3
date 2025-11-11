defmodule TriviaMultijugador.CLI do
  def start do
    IO.puts("🎮 TRIVIA MULTIJUGADOR")
    main_loop(nil)
  end

  defp main_loop(username) do
    IO.puts("\n" <> String.duplicate("=", 30))

    if username do
      IO.puts("Usuario: #{username}")
      IO.puts("1. Crear partida")
      IO.puts("2. Salir")
    else
      IO.puts("1. Conectar/Registrar")
      IO.puts("2. Salir")
    end

    IO.puts(String.duplicate("=", 30))

    case IO.gets("Opción: ") |> String.trim() do
      "1" when username == nil -> login_flow()
      "1" when username != nil -> create_game_flow(username)
      "2" -> IO.puts("¡Hasta pronto!"); System.halt(0)
      _ -> IO.puts("Opción inválida"); main_loop(username)
    end
  end

  defp login_flow do
    username = IO.gets("Usuario: ") |> String.trim()
    password = IO.gets("Contraseña: ") |> String.trim()

    case TriviaMultijugador.Server.connect(username, password) do
      {:ok, message} ->
        IO.puts("✅ #{message}")
        main_loop(username)
      {:error, reason} ->
        IO.puts("❌ #{reason}")
        main_loop(nil)
    end
  end

  defp create_game_flow(username) do
    topic = IO.gets("Tema (ciencia/historia): ") |> String.trim()

    case TriviaMultijugador.Server.create_game(username, topic, 3, 15) do
      {:ok, game_id} ->
        IO.puts("✅ Partida #{game_id} creada!")
        IO.puts("🎯 La partida comenzará en 2 segundos...")
        # Auto-iniciar la partida
        Process.sleep(2000)
        TriviaMultijugador.Game.start_game(game_id)
        main_loop(username)

      {:error, reason} ->
        IO.puts("❌ #{reason}")
        main_loop(username)
    end
  end
end
