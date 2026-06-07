import Component from '@ember/component';
import { computed } from '@ember/object';
import { action, set } from '@ember/object';
import { inject as service } from '@ember/service';

export default Component.extend({
  tagName: '',
  gameApi: service(),
  flashMessages: service(),

  showSheet: false,
  showAttackRoll: false,
  showSaveRoll: false,
  showSkillRoll: false,
  showAbilityRoll: false,
  showGenericRoll: false,
  showCombatTracker: false,

  sheet: null,
  combat: null,
  saveCategory: 'death',
  skillKey: null,
  abilityKey: 'str',
  abilityTarget: '',
  attackTargetAc: '',
  diceString: '1d20',
  isRolling: false,
  isCombatLoading: false,

  didInsertElement() {
    this._super(...arguments);
    this.loadSheet();
  },

  saveCategories: computed(function() {
    return [
      { key: 'death', label: 'Death' },
      { key: 'wands', label: 'Wands' },
      { key: 'paralysis', label: 'Paralysis' },
      { key: 'breath', label: 'Breath' },
      { key: 'spells', label: 'Spells' }
    ];
  }),

  skillOptions: computed('sheet.thief_skills.[]', function() {
    return (this.sheet && this.sheet.thief_skills) || [];
  }),

  sortedCombatants: computed('combat.combatants.@each.initiative', function() {
    return (this.combat && this.combat.combatants) || [];
  }),

  playDiceSound() {
    if (!this._diceAudio) {
      this._diceAudio = new Audio('/sounds/osr-rpg-dice.mp3');
      this._diceAudio.volume = 0.5;
    }
    this._diceAudio.currentTime = 0;
    this._diceAudio.play().catch(() => {});
  },

  loadSheet() {
    let api = this.gameApi;
    let sceneId = this.get('scene.id');
    let sender = this.get('scene.poseChar.name');
    if (!sceneId || !sender) { return; }

    api.requestOne('osrRpgSceneSheet', { id: sceneId, sender: sender }, null)
      .then((response) => {
        if (response.error) { return; }
        this.set('sheet', response.sheet);
        if (this.skillOptions.length) {
          this.set('skillKey', this.skillOptions[0].key);
        }
      });
  },

  loadCombat() {
    let sceneId = this.get('scene.id');
    if (!sceneId) { return Promise.resolve(); }
    this.set('isCombatLoading', true);
    return this.gameApi.requestOne('osrRpgSceneCombat', { id: sceneId, action: 'get' }, null)
      .then((response) => {
        if (!response.error) {
          this.set('combat', response);
        }
      })
      .finally(() => {
        this.set('isCombatLoading', false);
      });
  },

  sceneRoll(rollType, extra) {
    let api = this.gameApi;
    let sceneId = this.get('scene.id');
    let sender = this.get('scene.poseChar.name');
    if (!sceneId || !sender) {
      this.flashMessages.danger('No pose character selected.');
      return Promise.resolve();
    }

    this.set('isRolling', true);
    this.playDiceSound();
    let args = { id: sceneId, sender: sender, roll_type: rollType, ...extra };
    return api.requestOne('osrRpgSceneRoll', args, null)
      .then((response) => {
        if (response.error) {
          this.flashMessages.danger(response.error);
        }
      })
      .finally(() => {
        this.set('isRolling', false);
      });
  },

  combatAction(action, extra = {}) {
    let sceneId = this.get('scene.id');
    if (!sceneId) { return Promise.resolve(); }
    return this.gameApi.requestOne('osrRpgSceneCombat', { id: sceneId, action: action, ...extra }, null)
      .then((response) => {
        if (response.error) {
          this.flashMessages.danger(response.error);
        } else {
          this.set('combat', response);
        }
      });
  },

  @action
  toggleSheet() {
    this.set('showSheet', !this.showSheet);
    if (this.showSheet && !this.sheet) {
      this.loadSheet();
    }
  },

  @action
  setShowAttackRoll(value) {
    this.set('showAttackRoll', value);
  },

  @action
  setShowSaveRoll(value) {
    this.set('showSaveRoll', value);
  },

  @action
  setShowSkillRoll(value) {
    this.set('showSkillRoll', value);
  },

  @action
  setShowAbilityRoll(value) {
    this.set('showAbilityRoll', value);
  },

  @action
  setShowGenericRoll(value) {
    this.set('showGenericRoll', value);
  },

  @action
  toggleCombatTracker() {
    let show = !this.showCombatTracker;
    this.set('showCombatTracker', show);
    if (show) {
      this.loadCombat();
    }
  },

  @action
  rollAttack() {
    this.set('showAttackRoll', false);
    let extra = {};
    if (this.attackTargetAc) {
      extra.target_ac = parseInt(this.attackTargetAc, 10);
    }
    this.sceneRoll('attack', extra);
  },

  @action
  rollSave() {
    this.set('showSaveRoll', false);
    this.sceneRoll('save', { save_category: this.saveCategory });
  },

  @action
  rollSkill() {
    this.set('showSkillRoll', false);
    this.sceneRoll('skill', { skill: this.skillKey });
  },

  @action
  rollAbility() {
    this.set('showAbilityRoll', false);
    let extra = { ability: this.abilityKey };
    if (this.abilityTarget) {
      extra.target = parseInt(this.abilityTarget, 10);
    }
    this.sceneRoll('ability', extra);
  },

  @action
  rollGeneric() {
    this.set('showGenericRoll', false);
    this.sceneRoll('generic', { dice_string: this.diceString });
  },

  @action
  saveCategoryChanged(event) {
    this.set('saveCategory', event.target.value);
  },

  @action
  skillKeyChanged(event) {
    this.set('skillKey', event.target.value);
  },

  @action
  abilityKeyChanged(event) {
    this.set('abilityKey', event.target.value);
  },

  @action
  abilityTargetChanged(event) {
    this.set('abilityTarget', event.target.value);
  },

  @action
  attackTargetAcChanged(event) {
    this.set('attackTargetAc', event.target.value);
  },

  @action
  diceStringChanged(event) {
    this.set('diceString', event.target.value);
  },

  @action
  startCombat() {
    this.combatAction('start');
  },

  @action
  endCombat() {
    this.combatAction('end');
  },

  @action
  joinCombat() {
    this.combatAction('join');
  }
});
