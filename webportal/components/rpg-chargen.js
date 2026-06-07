import { A } from '@ember/array';
import Component from '@ember/component';
import { computed } from '@ember/object';
import { action } from '@ember/object';

export default Component.extend({
  tagName: '',

  didInsertElement: function() {
    this._super(...arguments);
    let self = this;
    this.set('updateCallback', function() { return self.onUpdate(); });
    let scores = {};
    (this.get('rpg.abilities') || []).forEach(ab => {
      scores[ab] = this.get(`rpg.ability_scores.${ab}`);
    });
    this.set('abilityScores', scores);
    this.initThiefAllocations();
  },

  rpg: computed('model.char.rpg', function() {
    return this.get('model.char.rpg') || {};
  }),

  allClasses: computed('rpg.class_groups', function() {
    let result = [];
    (this.get('rpg.class_groups') || []).forEach(group => {
      (group.classes || []).forEach(cls => {
        result.push({
          ...cls,
          groupLabel: group.label,
          displayName: `${group.label}: ${cls.name}`
        });
      });
    });
    return result;
  }),

  selectedClass: computed('rpg.class', 'allClasses', function() {
    let key = this.get('rpg.class');
    if (!key) { return null; }
    return (this.allClasses || []).find(c => c.key === key);
  }),

  allowedAlignments: computed('selectedClass', 'rpg.alignments', function() {
    let cls = this.selectedClass;
    let all = this.get('rpg.alignments') || [];
    if (!cls || !cls.alignment_restrictions) { return all; }
    return all.filter(a => cls.alignment_restrictions.includes(a));
  }),

  showThiefAllocator: computed('selectedClass', function() {
    let cls = this.selectedClass;
    return cls && cls.skill_system === 'd6' && cls.l1_expertise_points;
  }),

  thiefSkillsForClass: computed('selectedClass', 'rpg.thief_skill_defs', function() {
    let cls = this.selectedClass;
    if (!cls || cls.skill_system !== 'd6') { return []; }
    let keys = cls.skill_set || [];
    if (keys.includes('all_eight')) {
      return this.get('rpg.thief_skill_defs') || [];
    }
    let defs = this.get('rpg.thief_skill_defs') || [];
    return defs.filter(d => keys.includes(d.key));
  }),

  thiefPointsSpent: computed('thiefAllocations.@each.points', function() {
    let allocs = this.thiefAllocations || [];
    return allocs.reduce((sum, a) => sum + (parseInt(a.points, 10) || 0), 0);
  }),

  thiefPointsRemaining: computed('thiefPointsSpent', 'rpg.l1_expertise_points', function() {
    let total = this.get('rpg.l1_expertise_points') || 4;
    return total - this.thiefPointsSpent;
  }),

  initThiefAllocations: function() {
    let existing = this.get('rpg.thief_skill_allocations') || {};
    let skills = this.thiefSkillsForClass || [];
    let allocs = skills.map(d => {
      let points = existing[d.key] || 0;
      return {
        key: d.key,
        name: d.name,
        points: points,
        chance: 1 + points
      };
    });
    this.set('thiefAllocations', A(allocs));
  },

  onUpdate: function() {
    let scores = {};
    (this.get('rpg.abilities') || []).forEach(ab => {
      scores[ab] = this.get(`abilityScores.${ab}`);
    });

    let thief_skills = {};
    if (this.showThiefAllocator) {
      (this.thiefAllocations || []).forEach(a => {
        if (a.points > 0) {
          thief_skills[a.key] = parseInt(a.points, 10);
        }
      });
    }

    return {
      class: this.get('rpg.class'),
      alignment: this.get('rpg.alignment'),
      ability_scores: scores,
      thief_skills: thief_skills
    };
  },

  @action
  classChanged(val) {
    this.set('rpg.class', val ? val.key : null);
    if (val && val.alignment_restrictions) {
      let current = this.get('rpg.alignment');
      if (current && !val.alignment_restrictions.includes(current)) {
        this.set('rpg.alignment', null);
      }
    }
    this.initThiefAllocations();
  },

  @action
  alignmentChanged(val) {
    this.set('rpg.alignment', val);
  },

  @action
  abilityChanged(ab, event) {
    let val = parseInt(event.target.value, 10);
    this.set(`abilityScores.${ab}`, isNaN(val) ? null : val);
  },

  @action
  thiefPointChanged(skillKey, event) {
    let val = parseInt(event.target.value, 10) || 0;
    val = Math.max(0, Math.min(4, val));
    let allocs = this.thiefAllocations || [];
    let idx = allocs.findIndex(a => a.key === skillKey);
    if (idx >= 0) {
      this.set(`thiefAllocations.${idx}.points`, val);
      this.set(`thiefAllocations.${idx}.chance`, 1 + val);
    }
  },

  @action
  rollAbilities() {
    let scores = {};
    (this.get('rpg.abilities') || []).forEach(ab => {
      let roll = 0;
      for (let i = 0; i < 3; i++) { roll += Math.floor(Math.random() * 6) + 1; }
      scores[ab] = roll;
    });
    this.set('abilityScores', scores);
  }
});
