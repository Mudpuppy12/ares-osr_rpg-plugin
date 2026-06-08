# Manual patch: scene Character Card + server data

**Core files:**

- `aresmush/plugins/scenes/helpers/web_data.rb`
- `ares-webportal/app/components/char-card.hbs`
- `ares-webportal/app/components/live-scene-control.hbs` (`@onShowCharCard`)

Full copy-paste snippets: **[CORE_ARES_PATCHES.md](../../CORE_ARES_PATCHES.md)** — sections *Server — scene Character Card data*, *Portal — Character Card*, and *Portal — live scene*.

`CharCardOsrRpg` components are copied automatically by `plugin/install`.
