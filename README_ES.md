# Flotilla

> Wrapper declarativo para Phoenix LiveView — model → update → view.

Flotilla te permite construir UIs de LiveView como estructuras de datos
componibles siguiendo **The Elm Architecture** en lugar de escribir
plantillas HEEx directamente. Todas las transiciones de estado, manejo
de eventos y rendering ocurren en un único módulo que se lee de arriba
a abajo.

[![Licencia](https://img.shields.io/badge/licencia-MIT-blue.svg)](LICENSE.md)
[![Elixir](https://img.shields.io/badge/elixir-~%201.14-purple.svg)](mix.exs)

## Inicio rápido

Añade Flotilla y Phoenix LiveView a tu `mix.exs`:

```elixir
def deps do
  [
    {:flotilla, "~> 0.1"},
    {:phoenix_live_view, "~> 1.0"}
  ]
end
```

Después, define un LiveView:

```elixir
defmodule MyAppWeb.DashboardLive do
  use Flotilla.View

  @impl Flotilla.View.Behaviour
  def model(_params, _session, _socket) do
    %{count: 0, items: [], loading: false}
  end

  @impl Flotilla.View.Behaviour
  def update(:increment, model), do: %{model | count: model.count + 1}
  def update(:decrement, model), do: %{model | count: model.count - 1}
  def update({:set_items, items}, model), do: %{model | items: items, loading: false}
  def update(:load, model), do: %{model | loading: true}
  def update(_, model), do: model  # catch-all

  @impl Flotilla.View.Behaviour
  def view(model) do
    col([
      row([
        button("−", msg: :decrement),
        text("#{model.count}"),
        button("+", msg: :increment),
        button("Cargar", msg: :load)
      ]),
      if model.loading do
        spinner()
      else
        table(model.items, columns: [:id, :name, :status])
      end
    ])
  end
end
```

Conectalo en tu router como un LiveView normal:

```elixir
live "/dashboard", MyAppWeb.DashboardLive, :index
```

Eso es todo — sin archivo de plantilla, sin `mount` separado, sin
boilerplate de `handle_event`.

## Cómo funciona

```
        ┌─────────────────────────┐
        │  use Flotilla.View      │
        │  (macro)                │
        └─────────────┬───────────┘
                      │
                      ▼
   ┌──────────────────────────────────────┐
   │ Tu módulo implementa:                │
   │   model/3  →  estado inicial         │
   │   update/2 →  transición pura        │
   │   view/1   →  árbol VDOM             │
   └─────────────────┬────────────────────┘
                     │
                     ▼
   ┌──────────────────────────────────────┐
   │ El macro Flotilla.View genera:      │
   │   mount/3         (llama a model/3)  │
   │   handle_event/3  (llama a update/2) │
   │   render/1        (llama a view/1 +  │
   │                    Renderer.to_heex)  │
   └──────────────────────────────────────┘
```

## Componentes

| Contenedores | `col`, `row`, `card` |
|---|---|
| **Texto** | `text`, `heading`, `badge` |
| **Controles** | `button`, `input`, `select`, `checkbox` |
| **Datos** | `table`, `list`, `key_value` |
| **Estados** | `spinner`, `empty`, `error` |

Todos los helpers aceptan una keyword list `opts`; pasá `:class` para
sobreescribir las clases Tailwind por defecto, `:msg` para conectar
`phx-click`, `:on_change` para `phx-change`, etc.

## ¿Por qué no escribir HEEx directamente?

- **Estado en un solo lugar**: model, transiciones y vista viven en un
  único módulo en lugar de estar dispersos entre mount + handle_event + .heex.
- **Updates de función pura**: `update/2` es total y pura — fácil de
  razonar, fácil de testear.
- **Vistas componibles**: los árboles VDOM son solo datos. Podés crear
  un helper que devuelva vdom y llamarlo desde varias vistas.
- **Análisis estático**: Credo, Dialyzer y el sistema de tipos entienden
  tu función de vista porque es código Elixir, no un lenguaje de templates.

## Configuración

`Flotilla` es solo librería — no hay nada que arrancar en tu árbol de
supervisión. Solo `use Flotilla.View` y listo.

Las dependencias opcionales de dev (solo usadas por `mix format` /
`mix credo` / `mix dialyzer`) se incluyen vía `deps/0` en `mix.exs`.

## Licencia

MIT — ver [LICENSE.md](LICENSE.md).
