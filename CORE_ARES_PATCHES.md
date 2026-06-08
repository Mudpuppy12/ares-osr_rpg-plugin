# Core Ares Integration for OSR RPG

**Prerequisite:** complete [Step 1 in README.md](README.md#install) (`plugin/install`).

---

## Hook install

Use [Ares custom hook files](https://aresmush.com/tutorials/code/hooks/) only — do **not** also add OSR blocks to core templates (`live-scene-control.hbs`, `char-card.hbs`, etc.) or menus and tabs will appear twice.

### Run the installer

```bash
ARESMUSH_PATH=/path/to/aresmush WEBPORTAL_PATH=/path/to/ares-webportal ./scripts/install_hooks.sh
```

Run from this plugin repo after `plugin/install`. Re-run after plugin upgrades (backs up non-empty existing hook files).

### What the script installs

| Destination | Plugin source |
|-------------|---------------|
| `aresmush/plugins/chargen/custom_app_review.rb` | `game/hooks/chargen/` |
| `aresmush/plugins/profile/custom_char_fields.rb` | `game/hooks/profile/` |
| `aresmush/plugins/scenes/custom_char_card.rb` | `game/hooks/scenes/` |
| `ares-webportal/app/components/live-scene-custom-play.*` | `webportal/hooks/` |
| `ares-webportal/app/components/chargen-custom*` | `webportal/hooks/` |
| `ares-webportal/app/components/profile-custom*` | `webportal/hooks/` |
| `ares-webportal/app/components/char-card-custom-tabs*` | `webportal/hooks/` |
| `aresmush/game/styles/osr_rpg_chargen.scss` | `styles/` |
| `custom-routes.js` (four `osr-rpg-*` routes) | merged if missing |

### Still manual (game-specific)

| File | Action |
|------|--------|
| `game/config/website.yml` | Merge [website.osr_rpg.example.yml](game/config/website.osr_rpg.example.yml); set `character_gallery_group` / `character_gallery_subgroup` to match `demographics.yml` |
| `game/config/demographics.yml` | OSE example groups (Kingdom, Region, Profession) — your setting |
| `chargen-char.js` | Optional: save/review guardrails so shop cart survives validation failures ([manual section](#portal--chargen-controller)) |
| `scene-create.hbs` / `play.hbs` | Optional shop shortcut links |

### After hooks

| Change type | Command |
|-------------|---------|
| Server hook Ruby files | `load osr_rpg` or restart game server |
| Portal hooks / routes / styles | `cd ares-webportal && bin/deploy` |

### Install checklist

- [ ] `plugin/install` completed
- [ ] `scripts/install_hooks.sh` completed without errors
- [ ] `website.yml` System + Play menus; gallery groups match demographics
- [ ] `load osr_rpg` on game server
- [ ] Portal rebuilt
- [ ] Web chargen **Sheet** tab (custom hook); profile **Sheet** tab; live scene Play menu; Character Card sheet tab
- [ ] System → Spell Lists, Equipment List; Play → Equipment Shop

### Multi-plugin games

`custom_char_fields.rb` and `custom_char_card.rb` are single files per game. If you already use them for another system, merge OSR logic from `game/hooks/` into your existing hooks instead of overwriting blindly (the install script backs up files over 200 bytes).

---

## Manual core patches (reference)

If you cannot use hook files, `plugin/install` does not edit core AresMUSH or web portal source. Apply every patch below by hand.

### File index

| Core file | Required | If skipped |
|-----------|----------|------------|
| `aresmush/plugins/chargen/custom_app_review.rb` | Yes | Staff app review has no **OSR Sheet** section |
| `aresmush/plugins/chargen/helpers.rb` | Yes | Web chargen save ignores OSR sheet/cart/inventory |
| `aresmush/plugins/chargen/web/chargen_char_request_handler.rb` | Yes | Web chargen Sheet tab loads empty |
| `aresmush/plugins/chargen/web/chargen_info_request_handler.rb` | Yes | Chargen Sheet tab missing OSR intro blurb |
| `aresmush/plugins/scenes/helpers/web_data.rb` | Yes | Live-scene Character Card has no OSR sheet data |
| `ares-webportal/app/controllers/chargen-char.js` | Yes | Cart/inventory never saves; wrong API field name |
| `ares-webportal/app/templates/chargen-char.hbs` | Yes | No web chargen **Sheet** tab |
| `ares-webportal/app/components/profile-system.js` | Yes | Profile never shows OSR tab |
| `ares-webportal/app/components/profile-system.hbs` | Yes | No web profile sheet, equip, level-up, or HP buttons |
| `ares-webportal/app/components/live-scene-control.js` | Yes | Live scene Play menu has no OSR entries |
| `ares-webportal/app/components/live-scene-control.hbs` | Yes | No web rolls, Character Sheet, or combat tracker |
| `ares-webportal/app/components/char-card.hbs` | Yes | Character Card modal has no OSR **Character Sheet** tab |
| `ares-webportal/app/custom-routes.js` | Yes | Spell/equipment/shop pages 404 |
| `aresmush/game/config/website.yml` | Yes | No nav links; Characters/Roster may crash |
| `aresmush/game/config/demographics.yml` | Yes (OSE) | Chargen groups won't match your setting |
| `aresmush/game/styles/custom_style.scss` | Yes | Chargen, profile, shop, and reference UI look broken |
| `ares-webportal/app/templates/scene-create.hbs` | Optional | No shop link on Create Scene page |
| `ares-webportal/app/templates/play.hbs` | Optional | No shop shortcut in Play sidebar |
| `aresmush/game/config/chargen.yml` | Optional | Chargen review step still references FS3 instead of OSR |

Plugin components copied automatically by the installer (no core edit needed): `OsrRpgChargen`, `OsrRpgProfile`, `OsrRpgShop`, `LiveSceneOsrRpg`, `CharCardOsrRpg`, route files under `app/routes/`, templates under `app/templates/osr-rpg-*`.

---

## Server — app review

**File:** `aresmush/plugins/chargen/custom_app_review.rb`

At the start of `Chargen.custom_app_review(char)`:

```ruby
if Manage.is_extra_installed?("osr_rpg")
  return OsrRpg.app_review(char)
end
```

---

## Server — chargen save

**File:** `aresmush/plugins/chargen/helpers.rb`

In `Chargen.save_char`, after the Traits block (same pattern as FS3/Traits):

```ruby
if Manage.is_extra_installed?("osr_rpg")
  errors = OsrRpg.save_char(char, chargen_data)
  if (errors.any?)
    alerts.concat errors
  end
end
```

---

## Server — chargen web API

### `chargen_char_request_handler.rb`

**File:** `aresmush/plugins/chargen/web/chargen_char_request_handler.rb`

Before building the response hash, load OSR sheet data (after the Traits block):

```ruby
if Manage.is_extra_installed?("osr_rpg")
  osr_rpg = OsrRpg.get_sheet_for_web_editing(char, enactor)
else
  osr_rpg = nil
end
```

Add `osr_rpg:` to the returned hash alongside `fs3:` and `traits:`:

```ruby
{
  # ...existing fields...
  fs3: fs3,
  traits: traits,
  osr_rpg: osr_rpg,
  custom: Profile::CustomCharFields.get_fields_for_chargen(char)
}
```

### `chargen_info_request_handler.rb`

**File:** `aresmush/plugins/chargen/web/chargen_info_request_handler.rb`

Add `osr_rpg_blurb` to the returned hash (after `traits_blurb`):

```ruby
osr_rpg_blurb: Website.format_markdown_for_html(Global.read_config("osr_rpg", "osr_rpg_blurb")),
```

---

## Server — scene Character Card data

**File:** `aresmush/plugins/scenes/helpers/web_data.rb`

In `build_char_card_web_data`, add `osr_rpg` alongside `fs3` in the returned hash:

```ruby
fs3: FS3Skills.is_enabled? ? FS3Skills.build_web_char_data(char, viewer) : nil,
osr_rpg: (!Global.plugin_manager.is_disabled?('osr_rpg') ? OsrRpg::Rolls.scene_sheet(char) : nil)
```

---

## Portal — chargen controller

**File:** `ares-webportal/app/controllers/chargen-char.js`

### 1. Callback property

Add alongside other update callbacks:

```javascript
osrRpgUpdateCallback: null,
```

### 2. Plugin detection

`rpgExtraInstalled` must check `osr_rpg` (not `rpg`):

```javascript
rpgExtraInstalled: computed('model.app.game.extra_plugins', function () {
  return this.get('model.app.game.extra_plugins').some((e) => e == 'osr_rpg');
}),
```

### 3. Save payload key

In `buildQueryDataForChar`, read the OSR callback and send `osr_rpg:` (not `rpg:`):

```javascript
let rpg = this.osrRpgUpdateCallback ? this.osrRpgUpdateCallback() : null;

return {
  // ...existing fields...
  fs3: fs3,
  custom: custom,
  traits: traits,
  osr_rpg: rpg
};
```

### 4. Review blocks on validation errors

In `review()`, after a successful `chargenSave` response:

```javascript
clearList(this.charErrors, this, 'charErrors');
if (response.alerts && response.alerts.length) {
  response.alerts.forEach(r => pushObject(this.charErrors, r, this, 'charErrors'));
  this.flashMessages.danger('Fix the issues below before reviewing or submitting.');
  return;
}
if (this.rpgExtraInstalled) {
  this.send('reloadModel');
}
this.router.transitionTo('chargen-review', this.get('model.char.id'));
```

Cart/inventory commits only on a valid full-sheet save.

### 5. Save preserves cart on validation failure

In `save()`, set age before checking alerts; do **not** `reloadModel` when alerts exist:

```javascript
this.set('model.char.age', response.age);
if (response.alerts && response.alerts.length) {
  response.alerts.forEach( r => pushObject(this.charErrors, r, this, 'charErrors') );
  this.flashMessages.danger('Saved demographics, but the sheet has issues. Cart items commit only on a valid full save.');
  return;
}
if (this.rpgExtraInstalled) {
  this.send('reloadModel');
}
this.flashMessages.success('Saved!');
```

---

## Portal — chargen template

**File:** `ares-webportal/app/templates/chargen-char.hbs`

**Nav tab** (with other system tabs, e.g. after Traits):

```hbs
{{#if this.rpgExtraInstalled}}
<li role="presentation" class="nav-item"><a href="#rpgsheet" aria-controls="misc" role="tab" data-bs-toggle="tab" class="nav-link">Sheet</a></li>
{{/if}}
```

**Tab pane** (with other tab panels):

```hbs
{{#if this.rpgExtraInstalled}}
  <div role="tabpanel" class="tab-pane" id="rpgsheet">
    <OsrRpgChargen @model={{this.model}} @updateCallback={{this.osrRpgUpdateCallback}} />
  </div>
{{/if}}
```

---

## Portal — profile

### `profile-system.js`

**File:** `ares-webportal/app/components/profile-system.js`

```javascript
rpgExtraInstalled: computed('game.extra_plugins', function () {
  return this.get('game.extra_plugins').some((e) => e == 'osr_rpg');
}),
```

### `profile-system.hbs`

**File:** `ares-webportal/app/components/profile-system.hbs`

**Nav tab** (after Traits, before Fate):

```hbs
{{#if this.rpgExtraInstalled}}
  <li class="nav-item"><a data-bs-toggle="tab" class="nav-link" href="#systemrpg">Sheet</a></li>
{{/if}}
```

**Tab content** (with other profile panes):

```hbs
{{#if this.rpgExtraInstalled}}
  <OsrRpgProfile @char={{this.char}} />
{{/if}}
```

---

## Portal — live scene

### `live-scene-control.js`

**File:** `ares-webportal/app/components/live-scene-control.js`

```javascript
rpgExtraInstalled: computed(function() {
  return this.isExtraInstalled('osr_rpg');
}),
```

### `live-scene-control.hbs`

**File:** `ares-webportal/app/components/live-scene-control.hbs`

Inside the Play dropdown (same area as other extra-plugin menus):

```hbs
{{#if this.rpgExtraInstalled}}
  <LiveSceneOsrRpg @scene={{this.scene}} @onShowCharCard={{this.showCharCard}} />
{{/if}}
```

`@onShowCharCard` is required so Play → **Character Sheet** opens the scene Character Card modal.

---

## Portal — Character Card

**File:** `ares-webportal/app/components/char-card.hbs`

**Tab list** — after Description, before FS3:

```hbs
{{#if this.char.osr_rpg}}
  <li class="nav-item">
    <a data-bs-toggle="tab" class="nav-link" href="#osr-rpg-sheet">Character Sheet</a>
  </li>
{{/if}}
```

**Tab content** — after Description pane, before FS3:

```hbs
{{#if this.char.osr_rpg}}
  <div id="osr-rpg-sheet" class="tab-pane fade">
    <CharCardOsrRpg @char={{this.char}} />
  </div>
{{/if}}
```

`CharCardOsrRpg` is copied by `plugin/install`; only `char-card.hbs` and `web_data.rb` need manual edits.

---

## Portal — routes

**File:** `ares-webportal/app/custom-routes.js`

The installer copies route **files** under `app/routes/` but does **not** register them. Add:

```javascript
export default function setupCustomRoutes(router) {
  router.route('osr-rpg-spells', { path: '/osr_rpg/spells' });
  router.route('osr-rpg-spell-detail', { path: '/osr_rpg/spells/:tradition/:level/:name' });
  router.route('osr-rpg-equipment', { path: '/osr_rpg/equipment' });
  router.route('osr-rpg-shop', { path: '/osr_rpg/shop' });
}
```

Games that register routes in `router.js` instead should add the same four entries there. Rebuild the portal after editing.

---

## Game config — navbar and gallery

**File:** `aresmush/game/config/website.yml`

### Gallery groups (required)

Ares defaults `character_gallery_group` / `character_gallery_subgroup` to `Faction` / `Position`. Set them to real group names from your `demographics.yml`. For OSE Advanced Fantasy:

```yaml
character_gallery_group: Kingdom
character_gallery_subgroup: Region
```

If these don't match a demographics group, the portal **Characters** and **Roster** pages fail (`undefined method '[]' for nil` in the game log). Run in-game `config/check` after editing.

### System menu

Under `website.top_navbar` → **System** → `menu`:

```yaml
- title: Spell Lists
  route: osr-rpg-spells
- title: Equipment List
  route: osr-rpg-equipment
```

### Play menu

Under **Play** → `menu`, after **Start New Scene**:

```yaml
- title: Equipment Shop
  route: osr-rpg-shop
```

---

## Game config — demographics (OSE example)

**File:** `aresmush/game/config/demographics.yml`

Not shipped by the plugin — customize for your setting. OSE games typically use **Kingdom**, **Region**, and **Profession** groups. Example census fields:

```yaml
  - field: group
    width: 20
    title: Kingdom
    value: Kingdom
```

Ensure `website.yml` gallery group keys match group names defined here.

---

## Styles

**File:** `aresmush/game/styles/custom_style.scss`

Append the full contents of [`styles/osr_rpg_chargen.scss`](styles/osr_rpg_chargen.scss) from this plugin repo (~1000 lines). Covers chargen dice tray, profile sheet, live-scene dice tray, shop, combat tracker, and System reference pages.

Rebuild the portal after merging styles.

---

## Optional — scene-create and Play shop links

### `scene-create.hbs`

**File:** `ares-webportal/app/templates/scene-create.hbs`

After `<h1>Create a Scene</h1>`:

```hbs
<div class="alert alert-info">
  Need gear before your adventure?
  <LinkTo @route="osr-rpg-shop" class="btn btn-sm btn-secondary">Equipment Shop</LinkTo>
</div>
```

### `play.hbs`

**File:** `ares-webportal/app/templates/play.hbs`

Inside the approved-player scene controls (e.g. after Create Scene):

```hbs
<TooltipButton @position="right" @message="Equipment Shop" @icon="fa fa-shopping-cart" @route="osr-rpg-shop" />
```

---

## Optional — chargen review step text

**File:** `aresmush/game/config/chargen.yml`

Replace the FS3 **sheet** review step with OSR guidance:

```yaml
    sheet:
      title: OSR Character Sheet
      text: Set up your OSR stats in-game with %xhosr_rpg/classes%xn, %xhosr_rpg/class%xn, %xhosr_rpg/roll%xn, and %xhosr_rpg/finish%xn — or use the web portal Sheet tab. See %xhhelp osr_rpg%xn for the full command list.
    abilities:
      help: osr_rpg_chargen
```

---

## Manual install checklist

After `plugin/install` and all required patches above:

- [ ] `custom_app_review.rb` calls `OsrRpg.app_review`
- [ ] `chargen/helpers.rb` calls `OsrRpg.save_char`
- [ ] `chargen_char_request_handler.rb` returns `osr_rpg` payload
- [ ] `chargen_info_request_handler.rb` returns `osr_rpg_blurb`
- [ ] `web_data.rb` includes `osr_rpg` in Character Card data
- [ ] `chargen-char.js` — `osrRpgUpdateCallback`, `osr_rpg:` payload, save/review guardrails
- [ ] `chargen-char.hbs` — Sheet tab + `OsrRpgChargen`
- [ ] `profile-system.js` / `.hbs` — `rpgExtraInstalled` + `OsrRpgProfile`
- [ ] `live-scene-control.js` / `.hbs` — `rpgExtraInstalled` + `LiveSceneOsrRpg` with `@onShowCharCard`
- [ ] `char-card.hbs` — Character Sheet tab + `CharCardOsrRpg`
- [ ] `custom-routes.js` — all four `osr-rpg-*` routes
- [ ] `website.yml` — gallery groups, System + Play menu entries
- [ ] `custom_style.scss` — merged `osr_rpg_chargen.scss`
- [ ] (Optional) `scene-create.hbs`, `play.hbs`, `chargen.yml` OSR step
- [ ] `load osr_rpg` on game server
- [ ] Portal rebuilt (`bin/deploy`)

**Verify:**

- Web chargen **Sheet** tab with **Equipment & Gear** shop (after class selected)
- Chargen **Budget** shows rolled starting gold (30–180 gp); cart saves on valid full-sheet **Save**
- Web profile **Sheet** tab — equipment equip/unequip on your own character
- Play → **Equipment Shop** (approved characters)
- Live scene Play menu — Character Sheet, rolls, combat tracker
- Live scene Character Card (portrait click) — **Character Sheet** tab
- System → **Spell Lists** and **Equipment List**
- Telnet `osr_rpg/finish` and `sheet`; app review shows **OSR Sheet**

---

## Upgrade re-check

Re-run `plugin/install`, then `scripts/install_hooks.sh`. Merge `game/config/` YAML manually on re-install (installer skips config overwrite).

For manual core patches: `plugin/install` updates plugin code but **does not** re-apply those edits. On upgrade:

1. Run `plugin/install` (see [Upgrading](README.md#upgrading) in README).
2. Review [CHANGELOG.md](CHANGELOG.md) for new manual steps.
3. Diff these core files against this document:
   - `custom_app_review.rb`, `chargen/helpers.rb`, `chargen_char_request_handler.rb`, `chargen_info_request_handler.rb`, `web_data.rb`
   - `chargen-char.js`, `chargen-char.hbs`, `profile-system.*`, `live-scene-control.*`, `char-card.hbs`
   - `custom-routes.js`, `website.yml`, `custom_style.scss`
4. Merge any new YAML from this repo's `game/config/` into your game (installer skips `game/config/` on re-install).
5. `load osr_rpg` and rebuild portal if routes or styles changed.
