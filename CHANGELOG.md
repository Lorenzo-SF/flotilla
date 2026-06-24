# Changelog

All notable changes to Flotilla are documented in this file.

## [0.1.0] — 2026-06-24

### Added

- `Flotilla.View` macro (`use Flotilla.View`) — converts a module into a
  Phoenix LiveView following The Elm Architecture (`model → update → view`).
- `Flotilla.View.Behaviour` — the three callbacks `model/3`, `update/2`,
  `view/1`.
- `Flotilla.VDOM` — tagged-tuple virtual DOM type and `walk/2` helper.
- `Flotilla.Components` — 16 builder helpers: containers (`col`, `row`,
  `card`), text (`text`, `heading`, `badge`), controls (`button`, `input`,
  `select`, `checkbox`), data (`table`, `list`, `key_value`), and states
  (`spinner`, `empty`, `error`).
- `Flotilla.Renderer` — VDOM → HEEx converter with Tailwind-style default
  classes that consumers can override via `:class`.
- Tests for `Flotilla.Components`, `Flotilla.VDOM`, and `Flotilla.Renderer`
  (the latter skipped if Phoenix.LiveView is not loaded).
- README + README_ES (Spanish) and MIT LICENSE.
- CI workflow (lint + test + dialyzer).
