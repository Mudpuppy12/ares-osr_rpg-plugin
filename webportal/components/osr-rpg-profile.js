import Component from '@ember/component';
import { computed, set } from '@ember/object';
import { action } from '@ember/object';
import { inject as service } from '@ember/service';

const SAVE_CATEGORIES = [
  { key: 'death', label: 'Death', abbr: 'D' },
  { key: 'wands', label: 'Wands', abbr: 'W' },
  { key: 'paralysis', label: 'Paralysis', abbr: 'P' },
  { key: 'breath', label: 'Breath', abbr: 'B' },
  { key: 'spells', label: 'Spells', abbr: 'S' }
];

export default Component.extend({
  tagName: '',
  gameApi: service(),
  flashMessages: service(),
  session: service(),
  isLeveling: false,
  isBusy: false,

  sheet: computed('char.osr_rpg', 'char.custom.osr_rpg', function() {
    return this.get('char.osr_rpg') || this.get('char.custom.osr_rpg') || {};
  }),

  equipmentList: computed('char.osr_rpg', 'char.custom.osr_rpg', 'char.osr_rpg.equipment.[]', 'char.custom.osr_rpg.equipment.[]', function() {
    let sheet = this.get('char.osr_rpg') || this.get('char.custom.osr_rpg') || {};
    return sheet.equipment || [];
  }),

  inventoryList: computed('char.osr_rpg', 'char.custom.osr_rpg', 'char.osr_rpg.inventory.[]', 'char.custom.osr_rpg.inventory.[]', function() {
    let sheet = this.get('char.osr_rpg') || this.get('char.custom.osr_rpg') || {};
    return sheet.inventory || [];
  }),

  hasEquipmentSection: computed('equipmentList.[]', 'inventoryList.[]', function() {
    return this.equipmentList.length > 0 || this.inventoryList.length > 0;
  }),

  displayName: computed('char.fullname', 'char.name', function() {
    return this.get('char.fullname') || this.get('char.name') || '';
  }),

  explorationSkills: computed('sheet.exploration_skills.[]', function() {
    return this.get('sheet.exploration_skills') || [];
  }),

  saveCategories: computed('sheet.saves', function() {
    let saves = this.get('sheet.saves') || {};
    return SAVE_CATEGORIES.map(cat => ({
      ...cat,
      value: saves[cat.key] ?? saves[cat.key.toString()] ?? '—'
    }));
  }),

  isOwnProfile: computed(
    'char.id',
    'char.name',
    'session.data.authenticated.id',
    'session.data.authenticated.name',
    function() {
      let auth = this.get('session.data.authenticated') || {};
      let charId = this.get('char.id');
      if (auth.id != null && charId != null) {
        return String(auth.id) === String(charId);
      }
      return this.get('char.name') === auth.name;
    }
  ),

  itemCanEquip(item) {
    if (!item) { return false; }
    if (item.equippable === true || item.equippable === 'true') { return true; }
    let category = item.category;
    return category === 'armor' || category === 'weapons';
  },

  modDisplay(ab) {
    let mod = ab.modifier;
    if (mod === null || mod === undefined) { return ''; }
    return mod >= 0 ? `+${mod}` : `${mod}`;
  },

  spellDetailKey(name) {
    return (name || '').toString().trim().toLowerCase()
      .replace(/\s+/g, '_')
      .replace(/[^a-z0-9_]/g, '');
  },

  updateSheet(response) {
    if (response.sheet && this.char) {
      set(this.char, 'osr_rpg', response.sheet);
      if (this.get('char.custom')) {
        set(this.char, 'custom.osr_rpg', response.sheet);
      }
    }
  },

  @action
  levelUp() {
    if (this.isLeveling) { return; }
    this.set('isLeveling', true);
    this.gameApi.requestOne('osrRpgLevelUp', {}, null)
      .then((response) => {
        if (response.error) {
          this.flashMessages.danger(response.error);
          return;
        }
        this.updateSheet(response);
        this.flashMessages.success(`Level ${response.level}! +${response.hp_added} HP.`);
      })
      .finally(() => {
        this.set('isLeveling', false);
      });
  },

  @action
  adjustHp(amount) {
    if (this.isBusy) { return; }
    this.set('isBusy', true);
    this.gameApi.requestOne('osrRpgAdjustHp', { amount: amount }, null)
      .then((response) => {
        if (response.error) {
          this.flashMessages.danger(response.error);
          return;
        }
        this.updateSheet(response);
      })
      .finally(() => {
        this.set('isBusy', false);
      });
  },

  @action
  restSpells() {
    if (this.isBusy) { return; }
    this.set('isBusy', true);
    this.gameApi.requestOne('osrRpgSpellAction', { action: 'rest' }, null)
      .then((response) => {
        if (response.error) {
          this.flashMessages.danger(response.error);
          return;
        }
        this.updateSheet(response);
        this.flashMessages.success(response.message || 'Rested.');
      })
      .finally(() => {
        this.set('isBusy', false);
      });
  },

  @action
  equipItem(itemKey) {
    if (!this.isOwnProfile || this.isBusy) { return; }
    this.set('isBusy', true);
    this.gameApi.requestOne('osrRpgEquip', { action: 'equip', item: itemKey }, null)
      .then((response) => {
        if (response.error) {
          this.flashMessages.danger(response.error);
          return;
        }
        this.updateSheet(response);
        this.flashMessages.success(response.message || 'Equipped.');
      })
      .finally(() => {
        this.set('isBusy', false);
      });
  },

  @action
  unequipItem(itemKey) {
    if (!this.isOwnProfile || this.isBusy) { return; }
    this.set('isBusy', true);
    this.gameApi.requestOne('osrRpgEquip', { action: 'unequip', item: itemKey }, null)
      .then((response) => {
        if (response.error) {
          this.flashMessages.danger(response.error);
          return;
        }
        this.updateSheet(response);
        this.flashMessages.success(response.message || 'Unequipped.');
      })
      .finally(() => {
        this.set('isBusy', false);
      });
  }
});
