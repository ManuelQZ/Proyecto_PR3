defmodule TriviaMultijugadorTest do
  use ExUnit.Case

  # No necesitamos setup porque la aplicación ya inicia los procesos

  test "registro y autenticación de usuario" do
    assert {:ok, "Usuario registrado y conectado"} =
           TriviaMultijugador.Server.connect("test_user", "password123")

    assert {:ok, "Conectado exitosamente"} =
           TriviaMultijugador.Server.connect("test_user", "password123")
  end

  test "creación de partida" do
    TriviaMultijugador.Server.connect("creator", "pass")
    assert {:ok, game_id} = TriviaMultijugador.Server.create_game("creator", "ciencia", 2, 10)
    assert is_integer(game_id)
  end

  test "unión a partida" do
    # Crear partida
    TriviaMultijugador.Server.connect("creator", "pass")
    {:ok, game_id} = TriviaMultijugador.Server.create_game("creator", "ciencia", 2, 10)

    # Unir jugador
    TriviaMultijugador.Server.connect("player", "pass")
    assert :ok = TriviaMultijugador.Game.add_player(game_id, "player")
  end

  test "obtención de preguntas" do
    preguntas = TriviaMultijugador.QuestionBank.get_questions("ciencia", 1)
    assert is_list(preguntas)
  end

  test "actualización de puntaje" do
    # Usar un usuario único para esta prueba
    username = "score_user_#{System.unique_integer()}"
    TriviaMultijugador.UserManager.register_user(username, "pass")
    TriviaMultijugador.UserManager.update_score(username, 10)
    assert {:ok, 10} = TriviaMultijugador.UserManager.get_score(username)
  end
end
