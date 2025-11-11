defmodule TriviaMultijugador.UserManager do
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def register_user(username, password) do
    Agent.update(__MODULE__, fn users ->
      if Map.has_key?(users, username) do
        users
      else
        Map.put(users, username, %{username: username, password: password, score: 0})
      end
    end)
  end

  def authenticate(username, password) do
    Agent.get(__MODULE__, fn users ->
      case Map.get(users, username) do
        %{password: ^password} -> {:ok, username}
        %{} -> {:error, "Contraseña incorrecta"}
        nil -> {:error, "Usuario no encontrado"}
      end
    end)
  end

  def get_score(username) do
    Agent.get(__MODULE__, fn users ->
      case Map.get(users, username) do
        %{score: score} -> {:ok, score}
        nil -> {:error, "Usuario no encontrado"}
      end
    end)
  end

  def update_score(username, points) do
    Agent.update(__MODULE__, fn users ->
      case Map.get(users, username) do
        nil -> users
        user -> Map.put(users, username, %{user | score: user.score + points})
      end
    end)
  end
end
