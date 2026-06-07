# Manual patch: scene Character Card + `web_data.rb`

Ares `plugin/install` does not modify core scenes helpers or `char-card.hbs`. Apply these changes so live-scene Character Cards include an OSR **Character Sheet** tab.

## 1. `aresmush/plugins/scenes/helpers/web_data.rb`

In `build_char_card_web_data`, add `osr_rpg` alongside `fs3`:

```ruby
osr_rpg: (!Global.plugin_manager.is_disabled?('osr_rpg') ? OsrRpg::Rolls.scene_sheet(char) : nil)
```

Restart the game server or `load osr_rpg` after editing.

## 2. `ares-webportal/app/components/char-card.hbs`

**Tab list** — after the Description tab, before FS3:

```hbs
{{#if this.char.osr_rpg}}
  <li class="nav-item">
    <a data-bs-toggle="tab" class="nav-link" href="#osr-rpg-sheet">Character Sheet</a>
  </li>
{{/if}}
```

**Tab content** — after the Description pane, before FS3:

```hbs
{{#if this.char.osr_rpg}}
  <div id="osr-rpg-sheet" class="tab-pane fade">
    <CharCardOsrRpg @char={{this.char}} />
  </div>
{{/if}}
```

## 3. `ares-webportal/app/components/live-scene-control.hbs`

Pass the existing `showCharCard` action into `LiveSceneOsrRpg`:

```hbs
<LiveSceneOsrRpg @scene={{this.scene}} @onShowCharCard={{this.showCharCard}} />
```

## 4. Components

Copy from this plugin repo:

- `webportal/components/char-card-osr-rpg.hbs`
- `webportal/components/char-card-osr-rpg.js`
- Updated `live-scene-osr-rpg.hbs` / `.js` (Play → Character Sheet opens Character Card modal)

Rebuild the portal (`bin/deploy`) after copying components and patching `char-card.hbs`.
