import Component from '@ember/component';
import { computed } from '@ember/object';
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

  sheet: computed('char.osr_rpg', function() {
    return this.get('char.osr_rpg') || {};
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

  isOwnProfile: computed('char.name', 'session.data.authenticated.name', function() {
    return this.get('char.name') === this.get('session.data.authenticated.name');
  }),

  modDisplay(ab) {
    let mod = ab.modifier;
    if (mod === null || mod === undefined) { return ''; }
    return mod >= 0 ? `+${mod}` : `${mod}`;
  },

  updateSheet(response) {
    if (response.sheet) {
      this.set('char.osr_rpg', response.sheet);
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
  }
});
