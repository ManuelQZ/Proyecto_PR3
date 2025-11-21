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
        },
        %{
          id: 2,
          text: "¿Qué elemento químico tiene el símbolo 'O'?",
          options: %{"A" => "Oro", "B" => "Oxígeno", "C" => "Osmio", "D" => "Oganesón"},
          correct_answer: "B"
        },
        %{
          id: 3,
          text: "¿Cuántos huesos tiene el cuerpo humano adulto?",
          options: %{"A" => "186", "B" => "206", "C" => "226", "D" => "246"},
          correct_answer: "B"
        }
      ],
      "historia" => [
        %{
          id: 1,
          text: "¿En qué año llegó Colón a América?",
          options: %{"A" => "1492", "B" => "1500", "C" => "1520", "D" => "1488"},
          correct_answer: "A"
        },
        %{
          id: 2,
          text: "¿Quién pintó la Mona Lisa?",
          options: %{"A" => "Miguel Ángel", "B" => "Leonardo da Vinci", "C" => "Rafael", "D" => "Donatello"},
          correct_answer: "B"
        },
        %{
          id: 3,
          text: "¿Cuándo comenzó la Primera Guerra Mundial?",
          options: %{"A" => "1912", "B" => "1914", "C" => "1916", "D" => "1918"},
          correct_answer: "B"
        }
      ]
    }

    Agent.start_link(fn -> questions end, name: __MODULE__)
  end

  def get_questions(topic, count) do
    normalized_topic = String.downcase(topic)

    Agent.get(__MODULE__, fn questions ->
      questions
      |> Map.get(normalized_topic, [])
      |> Enum.take(count)
    end)
  end
end
