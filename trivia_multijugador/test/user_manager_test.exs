defmodule UserManagerTest do
  use ExUnit.Case

  test "registro de usuario" do
    username = "test_user_#{System.unique_integer()}"
    TriviaMultijugador.UserManager.register_user(username, "password")
    assert {:ok, username} = TriviaMultijugador.UserManager.authenticate(username, "password")
  end

  test "error con usuario no registrado" do
    username = "no_existe_#{System.unique_integer()}"
    assert {:error, "Usuario no encontrado"} =
           TriviaMultijugador.UserManager.authenticate(username, "password")
  end

  test "error con contraseña incorrecta" do
    username = "user_#{System.unique_integer()}"
    TriviaMultijugador.UserManager.register_user(username, "correct_password")
    assert {:error, "Contraseña incorrecta"} =
           TriviaMultijugador.UserManager.authenticate(username, "wrong_password")
  end

  test "actualización de puntaje" do
    username = "player_#{System.unique_integer()}"
    TriviaMultijugador.UserManager.register_user(username, "pass")

    # Puntaje inicial debería ser 0
    assert {:ok, 0} = TriviaMultijugador.UserManager.get_score(username)

    # Actualizar puntaje
    TriviaMultijugador.UserManager.update_score(username, 25)
    assert {:ok, 25} = TriviaMultijugador.UserManager.get_score(username)
  end
end
