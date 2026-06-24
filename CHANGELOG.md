# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **47 components**, organised by purpose:
  - **Containers**: `divider`, `grid`, `stack`, `center`, `segment`, `sidebar`
  - **Text**: `label`, `code`, `pre`, `kbd`, `blockquote`, `link`, `icon`
  - **Forms**: `form`, `field`, `textarea`, `radio_group`, `switch`, `slider`, `datepicker`, `submit`
  - **Navigation**: `menu`, `breadcrumb`, `pagination`, `tabs`, `navbar`, `stepper`
  - **Data**: `stat`, `timeline`, `avatar`, `tree`
  - **Feedback**: `progress`, `alert`, `toast`, `skeleton`, `notification`
- `Flotilla.Colors` — optional Pote bridge for color-aware component opts
  (`:color`, `:bg`, `:border`, `:ring`, `:fill`). Works without Pote
  installed (passes the input through as a CSS string).
- `Flotilla.Loader` — optional Arrea bridge for parallel row loading
  via `:loader` + `:parallel: true`. Falls back to sequential when
  Arrea is not loaded.
- `pote ~> 1.0` and `arrea ~> 1.0` as **optional** dependencies in
  `mix.exs`. Both are loaded via `Code.ensure_loaded?/2` and the
  library works without them.
- New tests in `test/flotilla/colors_test.exs` and
  `test/flotilla/loader_test.exs`. Extended
  `test/flotilla/components_test.exs` covers all new components.
- Full component catalogue in `README.md`.

### Changed
- `Flotilla.VDOM` `@type tag` now enumerates all 47 supported tags.
- `Flotilla.Renderer` adds default Tailwind classes for every new
  component. The unknown-tag fallback (`data-tag=`) still applies
  to user-defined custom tags.
- `mix.exs`:
  - `files:` updated to reference `docs/README.es.md` (was the old
    `README_ES.md` path).
  - `homepage_url:` already aligned with `source_url:`.

## [0.1.0] - 2026-06-10

### Added
- Initial release: 16 components, VDOM types, `use Flotilla.View` macro,
  `Flotilla.Renderer`, default Tailwind classes.

[0.1.0]: https://github.com/Lorenzo-SF/flotilla/releases/tag/v0.1.0