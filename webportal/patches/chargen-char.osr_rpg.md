# Manual patch: `ares-webportal/app/controllers/chargen-char.js`

Ares `plugin/install` does not modify core portal controllers. Apply these changes so OSR chargen data is included in save/review requests and cart/inventory commits reliably.

## 1. OSR callback and payload key

- Rename `rpgUpdateCallback` → `osrRpgUpdateCallback`
- In `rpgExtraInstalled`, check `osr_rpg` (not `rpg`)
- In `buildQueryDataForChar`, use `osrRpgUpdateCallback` and send `osr_rpg:` (not `rpg:`)

Match `chargen-char.hbs`: `<OsrRpgChargen @updateCallback={{this.osrRpgUpdateCallback}} />`

## 2. Review blocks on validation errors

In `review()`, after a successful `chargenSave` response:

- Clear `charErrors`, push `response.alerts` if any
- If alerts exist: show danger flash *"Fix the issues below before reviewing or submitting."* and **return** (do not navigate)
- If OSR installed: `reloadModel` before transitioning to `chargen-review`

Cart/inventory commits only on a valid full-sheet save.

## 3. Save preserves cart on validation failure

In `save()`:

- Set `model.char.age` before checking alerts
- If alerts exist: show danger flash about sheet issues; **return without `reloadModel`** (keeps shop cart in UI)
- If no alerts and OSR installed: `reloadModel`, then success flash
