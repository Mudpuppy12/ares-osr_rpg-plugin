import Component from '@ember/component';
import { computed } from '@ember/object';

const SAVE_CATEGORIES = [
  { key: 'death', label: 'Death', abbr: 'D' },
  { key: 'wands', label: 'Wands', abbr: 'W' },
  { key: 'paralysis', label: 'Paralysis', abbr: 'P' },
  { key: 'breath', label: 'Breath', abbr: 'B' },
  { key: 'spells', label: 'Spells', abbr: 'S' }
];

export default Component.extend({
  tagName: '',

  sheet: computed('char.osr_rpg', function() {
    return this.get('char.osr_rpg') || {};
  }),

  equipmentList: computed('char.osr_rpg.equipment.[]', function() {
    return this.get('char.osr_rpg.equipment') || [];
  }),

  inventoryList: computed('char.osr_rpg.inventory.[]', function() {
    return this.get('char.osr_rpg.inventory') || [];
  }),

  hasEquipmentSection: computed('equipmentList.[]', 'inventoryList.[]', function() {
    return this.equipmentList.length > 0 || this.inventoryList.length > 0;
  }),

  displayName: computed('sheet.name', 'sheet.char_name', 'char.name', function() {
    return this.get('sheet.name') || this.get('sheet.char_name') || this.get('char.name') || '';
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

  modDisplay(ab) {
    let mod = ab.modifier;
    if (mod === null || mod === undefined) { return ''; }
    return mod >= 0 ? `+${mod}` : `${mod}`;
  }
});
