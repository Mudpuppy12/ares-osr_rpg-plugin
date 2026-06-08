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

const DICE_TYPES = [4, 6, 8, 10, 12, 20];

export default Component.extend({
  tagName: '',
  gameApi: service(),
  flashMessages: service(),

  showAttackRoll: false,
  showSaveRoll: false,
  showSkillRoll: false,
  showAbilityRoll: false,
  showGenericRoll: false,
  showCombatTracker: false,
  showCharCardModal: false,
  characterCardChar: null,

  sheet: null,
  combat: null,
  saveCategory: 'death',
  skillKey: null,
  abilityKey: 'str',
  abilityTarget: '',
  attackTargetAc: '',
  isRolling: false,
  isCombatLoading: false,
  _lastPoseCharId: null,

  diceTypes: DICE_TYPES,
  diceCounts: {
    4: 0,
    6: 0,
    8: 0,
    10: 0,
    12: 0,
    20: 0
  },

  didInsertElement() {
    this._super(...arguments);
    this._lastPoseCharId = this.get('scene.poseChar.id');
    this.loadSheet();
  },

  didUpdateAttrs() {
    this._super(...arguments);
    let poseId = this.get('scene.poseChar.id');
    if (poseId !== this._lastPoseCharId) {
      this._lastPoseCharId = poseId;
      this.set('sheet', null);
      this.loadSheet();
    }
  },

  rollSaveCategories: computed(function() {
    return SAVE_CATEGORIES;
  }),

  skillOptions: computed('sheet.thief_skills.[]', function() {
    return (this.sheet && this.sheet.thief_skills) || [];
  }),

  sortedCombatants: computed('combat.combatants.@each.initiative', function() {
    return (this.combat && this.combat.combatants) || [];
  }),

  dicePoolSummary: computed(
    'diceCounts.4',
    'diceCounts.6',
    'diceCounts.8',
    'diceCounts.10',
    'diceCounts.12',
    'diceCounts.20',
    function() {
      let parts = [];
      DICE_TYPES.forEach((sides) => {
        let count = this.get(`diceCounts.${sides}`) || 0;
        if (count > 0) {
          parts.push(`${count}d${sides}`);
        }
      });
      return parts.join('+');
    }
  ),

  dicePoolDisplay: computed('dicePoolSummary', function() {
    let summary = this.dicePoolSummary;
    if (!summary) { return ''; }
    return summary.replace(/\+/g, ' + ');
  }),

  hasDicePool: computed('dicePoolSummary', function() {
    return !!this.dicePoolSummary;
  }),

  clearDicePool() {
    DICE_TYPES.forEach((sides) => {
      this.set(`diceCounts.${sides}`, 0);
    });
  },

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
  showCharacterCard() {
    let name = this.get('scene.poseChar.name');
    if (!name) {
      this.flashMessages.danger('No pose character selected.');
      return;
    }
    if (this.onShowCharCard) {
      this.onShowCharCard(name);
      return;
    }
    this.gameApi.requestOne('sceneCard', { char: name }, null)
      .then((response) => {
        if (response.error) {
          this.flashMessages.danger(response.error);
          return;
        }
        this.set('characterCardChar', response);
        this.set('showCharCardModal', true);
      });
  },

  @action
  hideCharCardModal() {
    this.set('showCharCardModal', false);
    this.set('characterCardChar', null);
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
    if (value) {
      this.clearDicePool();
    }
    this.set('showGenericRoll', value);
  },

  @action
  hideGenericRoll() {
    this.clearDicePool();
    this.set('showGenericRoll', false);
  },

  @action
  addDie(sides) {
    let count = this.get(`diceCounts.${sides}`) || 0;
    if (count < 10) {
      this.set(`diceCounts.${sides}`, count + 1);
    }
  },

  @action
  removeDie(sides) {
    let count = this.get(`diceCounts.${sides}`) || 0;
    if (count > 0) {
      this.set(`diceCounts.${sides}`, count - 1);
    }
  },

  @action
  clearDicePoolAction() {
    this.clearDicePool();
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
    if (!this.hasDicePool) {
      this.flashMessages.danger('Select at least one die to roll.');
      return;
    }
    let diceString = this.dicePoolSummary;
    this.set('showGenericRoll', false);
    this.clearDicePool();
    this.sceneRoll('generic', { dice_string: diceString });
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
