defmodule IntegrationTest do
  use ExUnit.Case

  test "flujo completo de juego" do
    # Usar nombres de usuario únicos
    user1 = "jugador1_#{System.unique_integer()}"
    user2 = "jugador2_#{System.unique_integer()}"

    # 1. Registro de usuarios
    assert {:ok, _} = TriviaMultijugador.Server.connect(user1, "pass1")
    assert {:ok, _} = TriviaMultijugador.Server.connect(user2, "pass2")

    # 2. Creación de partida
    assert {:ok, game_id} = TriviaMultijugador.Server.create_game(user1, "ciencia", 2, 5)

    # 3. Unión a partida
    assert :ok = TriviaMultijugador.Game.add_player(game_id, user1)
    assert :ok = TriviaMultijugador.Game.add_player(game_id, user2)

    # 4. Inicio de partida
    assert :ok = TriviaMultijugador.Game.start_game(game_id)

    # La partida debería estar iniciada
    # (En una prueba real podríamos verificar el estado)
  end

  test "múltiples partidas concurrentes" do
    # Crear múltiples partidas con usuarios únicos
    tasks = [
      Task.async(fn ->
        user = "user1_#{System.unique_integer()}"
        TriviaMultijugador.Server.connect(user, "pass")
        TriviaMultijugador.Server.create_game(user, "ciencia", 2, 10)
      end),
      Task.async(fn ->
        user = "user2_#{System.unique_integer()}"
        TriviaMultijugador.Server.connect(user, "pass")
        TriviaMultijugador.Server.create_game(user, "historia", 2, 10)
      end)
    ]

    results = Task.await_many(tasks, 5000)

    # Verificar que todas las partidas se crearon exitosamente
    Enum.each(results, fn result ->
      assert {:ok, _game_id} = result
    end)
  end
end
