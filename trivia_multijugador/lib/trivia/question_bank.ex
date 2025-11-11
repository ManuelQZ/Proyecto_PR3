defmodule TriviaMultijugador.QuestionBank do
  use Agent

  def start_link(_opts) do
    questions = %{
      "ciencia" => [
        %{
          id: 1,
          text: "¿Cuál es el planeta más grande del sistema solar?",
          options: %{"A" => "Marte", "B" => "Júpiter", "C" => "Saturno", "D" => "Neptuno"},
          correct_answer: "B"
        }
      ],
      "historia" => [
        %{
          id: 2,
          text: "¿En qué año llegó Colón a América?",
          options: %{"A" => "1492", "B" => "1500", "C" => "1520", "D" => "1488"},
          correct_answer: "A"
        }
      ]
    }

    Agent.start_link(fn -> questions end, name: __MODULE__)
  end

  def get_questions(topic, count) do
    Agent.get(__MODULE__, fn questions ->
      questions
      |> Map.get(topic, [])
      |> Enum.take(count)
    end)
  end
end
