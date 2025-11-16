# 🎮 Trivia Multijugador - Elixir/OTP

Sistema de trivia multijugador en tiempo real implementado en Elixir usando OTP. Permite crear partidas, competir con temporizador y manejar múltiples jugadores concurrentemente.

## Características

- **Multijugador en tiempo real**: Hasta 4 jugadores por partida
- **Temporizador configurable**: 15 segundos por pregunta
- **Sistema de puntuaciones**: Ranking en tiempo real
- **Autenticación automática**: Registro y login simplificado
- **Múltiples categorías**: Ciencia, historia y más
- **Arquitectura OTP**: Procesos concurrentes y tolerantes a fallos

## Cómo Empezar

### Requisitos
- Elixir 1.14+
- Erlang/OTP 25+

### Ejecutar la Aplicación

```bash
mix run -e "TriviaMultijugador.start()"
```

### Flujo Básico

1. **Conectar/Registrar usuario**
2. **Crear partida** (elige categoría y número de preguntas)
3. **La partida comienza automáticamente** después de 2 segundos
4. **Responde preguntas** con temporizador de 15 segundos
5. **Ve los resultados finales** y el ranking

## Arquitectura

### Componentes Principales

- **`TriviaMultijugador.Application`**: Punto de entrada OTP
- **`TriviaMultijugador.Supervisor`**: Gestor dinámico de partidas
- **`TriviaMultijugador.Server`**: Coordinador principal del sistema
- **`TriviaMultijugador.Game`**: Motor de partida individual (GenServer)
- **`TriviaMultijugador.UserManager`**: Gestión de usuarios (Agent)
- **`TriviaMultijugador.QuestionBank`**: Banco de preguntas (Agent)
- **`TriviaMultijugador.CLI`**: Interfaz de línea de comandos

## Ejemplos de Uso

### Desde IEx

```elixir
# Conectar usuario
TriviaMultijugador.Server.connect("ana", "123")

# Crear partida
{:ok, game_id} = TriviaMultijugador.Server.create_game("ana", "ciencia", 3, 15)
```

### Múltiples Partidas

```elixir
# Partidas simultáneas
{:ok, game1} = TriviaMultijugador.Server.create_game("user1", "ciencia", 5, 15)
{:ok, game2} = TriviaMultijugador.Server.create_game("user2", "historia", 3, 10)
```

## API Principal

```elixir
# Autenticación
{:ok, message} = TriviaMultijugador.Server.connect("usuario", "contraseña")

# Creación de partida
{:ok, game_id} = TriviaMultijugador.Server.create_game(usuario, tema, num_preguntas, segundos)

# Unirse a partida
:ok = TriviaMultijugador.Game.add_player(game_id, usuario)
```

## Testing

```bash
mix test
```

## Estructura del Proyecto

```
lib/
├── trivia_multijugador/
│   ├── application.ex
│   ├── supervisor.ex
│   ├── server.ex
│   ├── game.ex
│   ├── user_manager.ex
│   ├── question_bank.ex
│   └── cli.ex
└── trivia_multijugador.ex
```

## Características Técnicas

- **Concurrencia**: Cada partida es un GenServer independiente
- **Tolerancia a fallos**: Supervisor trees para recuperación automática
- **Escalabilidad**: Múltiples partidas simultáneas sin bloqueos
- **Comunicación**: Mensajes asíncronos entre procesos

## Flujo de Partida

1. **Preparación**: 2 segundos de cuenta regresiva
2. **Preguntas**: Secuencia con temporizador de 15 segundos
3. **Resultados**: Ranking final y actualización de puntuaciones

---

**Desarrollado por:** [Tu Nombre Aquí]