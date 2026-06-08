import { A } from '@ember/array';
import Component from '@ember/component';
import { computed } from '@ember/object';
import { action } from '@ember/object';
import { inject as service } from '@ember/service';

const ABILITY_NAMES = {
  str: 'Strength',
  dex: 'Dexterity',
  con: 'Constitution',
  int: 'Intelligence',
  wis: 'Wisdom',
  cha: 'Charisma'
};

function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function roll3d6Client() {
  let dice = [];
  for (let i = 0; i < 3; i++) {
    dice.push(Math.floor(Math.random() * 6) + 1);
  }
  return { dice, total: dice.reduce((a, b) => a + b, 0) };
}

export default Component.extend({
  tagName: '',
  gameApi: service(),

  rollMode: 'order',
  useServerRolls: true,
  isRolling: false,
  rollingAbility: null,
  abilityRolls: null,
  scorePool: null,
  poolAssignments: null,
  abilityRollCount: 0,
  dragOverAbility: null,
  draggingPoolId: null,
  shopCart: {},

  didInsertElement: function() {
    this._super(...arguments);
    let self = this;
    this.set('updateCallback', function() { return self.onUpdate(); });
    if (this.requireServerRolls) {
      this.set('useServerRolls', true);
    }
    let scores = {};
    (this.get('osr_rpg.abilities') || []).forEach(ab => {
      scores[ab] = this.get(`osr_rpg.ability_scores.${ab}`);
    });
    this.set('abilityScores', scores);
    this.set('abilityRolls', {});
    this.set('poolAssignments', {});
    this.set('abilityRollCount', this.get('osr_rpg.ability_roll_count') || 0);
    this.initThiefAllocations();
    this.initSpellPicks();
    this.initShopCart();
    this.bootstrapShopData();
  },

  didUpdateAttrs() {
    this._super(...arguments);
    this.initShopCart();
    this.bootstrapShopData();
  },

  setOsrRpgData(osr) {
    if (this.get('model.char.custom')) {
      this.set('model.char.custom.osr_rpg', osr);
    } else {
      this.set('model.char.osr_rpg', osr);
    }
  },

  currentOsrRpgData() {
    return this.get('model.char.osr_rpg') || this.get('model.char.custom.osr_rpg') || {};
  },

  async bootstrapShopData() {
    let budget = this.get('osr_rpg.starting_gold');
    if (budget != null && budget > 0) {
      return;
    }
    let id = this.get('model.char.id');
    if (!id) {
      return;
    }
    try {
      let response = await this.gameApi.requestOne('osrRpgEnsureStartingGold', { id: id });
      if (response && response.error) {
        return;
      }
      if (response && response.starting_gold > 0) {
        let osr = { ...this.currentOsrRpgData(), ...response };
        this.setOsrRpgData(osr);
      }
    } catch (_e) {
      // Shop will stay empty until chargen reloads.
    }
  },

  osr_rpg: computed('model.char.osr_rpg', 'model.char.custom.osr_rpg', function() {
    return this.get('model.char.osr_rpg') || this.get('model.char.custom.osr_rpg') || {};
  }),

  osrRpgBlurb: computed('model.cgInfo.osr_rpg_blurb', 'osr_rpg.osr_rpg_blurb', function() {
    return this.get('model.cgInfo.osr_rpg_blurb') || this.get('osr_rpg.osr_rpg_blurb') || '';
  }),

  requireServerRolls: computed('osr_rpg.require_server_rolls', function() {
    return this.get('osr_rpg.require_server_rolls') !== false;
  }),

  lockAbilityScores: computed('requireServerRolls', 'useServerRolls', function() {
    return this.requireServerRolls || this.useServerRolls;
  }),

  abilityModifiers: computed('osr_rpg.ability_modifiers', function() {
    return this.get('osr_rpg.ability_modifiers') || {};
  }),

  allClasses: computed('osr_rpg.class_groups', function() {
    let result = [];
    (this.get('osr_rpg.class_groups') || []).forEach(group => {
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

  selectedClass: computed('osr_rpg.class', 'allClasses', function() {
    let key = this.get('osr_rpg.class');
    if (!key) { return null; }
    return (this.allClasses || []).find(c => c.key === key);
  }),

  classDetailFacts: computed('selectedClass', function() {
    let cls = this.selectedClass;
    if (!cls) { return null; }

    let facts = [];
    let push = (label, value) => {
      if (value != null && value !== '') {
        facts.push({ label, value: String(value) });
      }
    };

    push('Hit Die', cls.hd);
    push('Max Level', cls.max_level);
    push('L1 THAC0', cls.l1_thac0);

    let saves = cls.l1_saves;
    if (saves && Object.keys(saves).length) {
      let saveOrder = ['death', 'wands', 'paralysis', 'breath', 'spells'];
      let saveLabels = {
        death: 'Death',
        wands: 'Wands',
        paralysis: 'Paralysis',
        breath: 'Breath',
        spells: 'Spells'
      };
      let parts = saveOrder
        .filter((k) => saves[k] != null)
        .map((k) => `${saveLabels[k]} ${saves[k]}`);
      push('L1 Saves', parts.join(', '));
    }

    let primes = (cls.prime_reqs || []).map((p) => p.toUpperCase()).join(', ');
    push('Prime Reqs', primes);

    let minScores = cls.min_scores || {};
    let minParts = Object.keys(minScores)
      .sort()
      .map((k) => `${k.toUpperCase()} ${minScores[k]}`);
    push('Min Scores', minParts.join(', '));

    let align = cls.alignment_restrictions;
    push('Alignment', (align && align.length) ? align.join(', ') : 'Any');

    if (cls.spell_tradition) {
      let traditionName = cls.spell_tradition
        .split('_')
        .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
        .join('-');
      let level = cls.spells_from_level || 1;
      push('Spellcasting', `${traditionName} spells from level ${level}`);
    }

    if (cls.skill_system === 'd6') {
      let skillText = 'd6 skills';
      if (cls.l1_expertise_points != null) {
        let pts = cls.l1_expertise_points;
        skillText += `; ${pts} expertise point${pts === 1 ? '' : 's'} at L1`;
      }
      push('Skills', skillText);
    }

    push('Armor', cls.armor);
    push('Weapons', cls.weapons);

    if (cls.race && cls.race !== 'human') {
      push('Race', cls.race.charAt(0).toUpperCase() + cls.race.slice(1));
    }

    let languages = (cls.languages || []).join(', ');

    return {
      blurb: cls.blurb || '',
      facts,
      languages,
      restrictions: cls.restrictions || [],
      specialAbilities: cls.special_abilities || []
    };
  }),

  sheetPreview: computed(
    'selectedClass',
    'osr_rpg.alignment',
    'abilityScores',
    'abilityScores.str',
    'abilityScores.dex',
    'abilityScores.con',
    'abilityScores.int',
    'abilityScores.wis',
    'abilityScores.cha',
    'abilityRolls',
    'thiefAllocations.@each.points',
    'spellPicks.[]',
    'cartLineItems.[]',
    'goldRemaining',
    'previewEquippedAc',
    'startingGoldBudget',
    'osr_rpg.hp_per_level',
    'abilityModifiers',
    function() {
      let cls = this.selectedClass;
      if (!cls) { return null; }

      let mods = this.abilityModifiers;
      let scores = this.get('abilityScores') || {};
      let rolls = this.get('abilityRolls') || {};
      let hpPerLevel = this.get('osr_rpg.hp_per_level');
      let rollHp = hpPerLevel === 'roll';

      let hp = null;
      let hpMax = null;
      let hpLabel = null;
      let conScore = scores.con;
      if (conScore === null || conScore === undefined || conScore === '') {
        conScore = rolls.con ? rolls.con.total : null;
      }
      if (conScore !== null && conScore !== undefined && conScore !== '') {
        let conMod = mods[String(parseInt(conScore, 10))] ?? 0;
        let modStr = conMod >= 0 ? `+${conMod}` : `${conMod}`;
        let hd = cls.hd || 'd6';
        if (rollHp) {
          hpLabel = `HP: ${hd}${modStr}`;
        } else {
          let die = parseInt(String(hd).replace('d', ''), 10) || 6;
          let value = Math.max(die + conMod, 1);
          hp = value;
          hpMax = value;
        }
      }

      let thiefSkills = [];
      if (cls.skill_system === 'd6') {
        (this.thiefAllocations || []).forEach(a => {
          let points = parseInt(a.points, 10) || 0;
          if (points > 0) {
            thiefSkills.push({
              name: a.name,
              chance: `${1 + points}-in-6`
            });
          }
        });
      }

      return {
        className: cls.name,
        race: cls.race || '—',
        thac0: cls.l1_thac0 != null ? cls.l1_thac0 : '—',
        hp: hp,
        hpMax: hpMax,
        hpLabel: hpLabel,
        thiefSkills: thiefSkills,
        spellSummary: this.spellSummaryForPreview(),
        startingGold: this.startingGoldBudget,
        goldRemaining: this.goldRemaining,
        cartSummary: (this.cartLineItems || []).map(i => i.qty > 1 ? `${i.name} x${i.qty}` : i.name).join(', '),
        previewAc: this.previewEquippedAc
      };
    }
  ),

  allowedAlignments: computed('selectedClass', 'osr_rpg.alignments', function() {
    let cls = this.selectedClass;
    let all = this.get('osr_rpg.alignments') || [];
    if (!cls || !cls.alignment_restrictions) { return all; }
    return all.filter(a => cls.alignment_restrictions.includes(a));
  }),

  showThiefAllocator: computed('selectedClass', function() {
    let cls = this.selectedClass;
    if (!cls || cls.skill_system !== 'd6') { return false; }
    return (cls.l1_expertise_points || this.get('osr_rpg.l1_expertise_points') || 4) > 0;
  }),

  l1ExpertisePoints: computed('selectedClass', 'osr_rpg.l1_expertise_points', function() {
    let cls = this.selectedClass;
    return (cls && cls.l1_expertise_points) || this.get('osr_rpg.l1_expertise_points') || 4;
  }),

  showSpellPicker: computed('selectedClass', function() {
    let cls = this.selectedClass;
    return cls && cls.casting_type === 'arcane' && (cls.l1_spell_slots || 0) > 0;
  }),

  showDivineSpellInfo: computed('selectedClass', function() {
    let cls = this.selectedClass;
    return cls && cls.casting_type === 'divine' && (cls.l1_spell_slots || 0) > 0;
  }),

  showRestrictedSpellInfo: computed('selectedClass', function() {
    let cls = this.selectedClass;
    return cls && cls.casting_type === 'restricted';
  }),

  divineTraditionLabel: computed('selectedClass', function() {
    let cls = this.selectedClass;
    return cls && cls.spell_tradition ? cls.spell_tradition.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase()) : '';
  }),

  restrictedL1SpellLabel: computed('selectedClass', function() {
    let cls = this.selectedClass;
    let spells = (cls && cls.l1_spells) || [];
    return spells.join(', ');
  }),

  requiredSpellPicks: computed('selectedClass', function() {
    let cls = this.selectedClass;
    return cls ? (cls.l1_spell_slots || 0) : 0;
  }),

  startingGoldBudget: computed('osr_rpg.starting_gold', function() {
    return this.get('osr_rpg.starting_gold') || 0;
  }),

  savedEquipment: computed('osr_rpg.equipment.[]', function() {
    return this.get('osr_rpg.equipment') || [];
  }),

  savedCarriedLines: computed('osr_rpg.inventory', 'shopCatalogSections', function() {
    let inv = this.get('osr_rpg.inventory') || {};
    let lines = [];
    Object.keys(inv).forEach(key => {
      let qty = parseInt(inv[key], 10) || 0;
      if (qty <= 0) { return; }
      let name = key;
      this.shopCatalogSections.forEach(section => {
        (section.items || []).forEach(item => {
          if (item.key === key) { name = item.name; }
        });
      });
      lines.push({ key, name, qty });
    });
    return lines;
  }),

  hasSavedGear: computed('savedEquipment.[]', 'savedCarriedLines.[]', function() {
    return this.savedEquipment.length > 0 || this.savedCarriedLines.length > 0;
  }),

  shopCatalogSections: computed('osr_rpg.equipment_catalog', function() {
    let catalog = this.get('osr_rpg.equipment_catalog') || {};
    return [
      { key: 'armor', title: 'Armor', items: catalog.armor || [] },
      { key: 'weapons', title: 'Melee Weapons', items: catalog.weapons || [] },
      { key: 'missile_weapons', title: 'Missile Weapons', items: catalog.missile_weapons || [] },
      { key: 'adventuring_gear', title: 'Adventuring Gear', items: catalog.adventuring_gear || [] }
    ].filter(section => section.items.length > 0);
  }),

  cartTotal: computed('shopCart', function() {
    let cart = this.shopCart || {};
    let total = 0;
    this.shopCatalogSections.forEach(section => {
      section.items.forEach(item => {
        let qty = cart[item.key] || 0;
        total += (item.cost || 0) * qty;
      });
    });
    return total;
  }),

  goldRemaining: computed('startingGoldBudget', 'cartTotal', function() {
    return (this.startingGoldBudget || 0) - (this.cartTotal || 0);
  }),

  cartLineItems: computed('shopCart', 'shopCatalogSections', function() {
    let cart = this.shopCart || {};
    let lines = [];
    this.shopCatalogSections.forEach(section => {
      section.items.forEach(item => {
        let qty = cart[item.key] || 0;
        if (qty > 0) {
          lines.push({
            key: item.key,
            name: item.name,
            qty: qty,
            lineTotal: (item.cost || 0) * qty
          });
        }
      });
    });
    return lines;
  }),

  previewEquippedAc: computed('shopCart', 'shopCatalogSections', function() {
    let cart = this.shopCart || {};
    let ac = 0;
    let bonus = 0;
    let armorItems = (this.shopCatalogSections.find(s => s.key === 'armor') || {}).items || [];
    ['leather', 'chain', 'plate'].forEach(armorKey => {
      if ((cart[armorKey] || 0) > 0) {
        let item = armorItems.find(i => i.key === armorKey);
        if (item && item.ac != null) {
          ac = Math.max(ac, item.ac);
        }
      }
    });
    if ((cart.shield || 0) > 0) {
      bonus += 1;
    }
    return ac + bonus;
  }),

  spellOptions: computed('selectedClass', function() {
    let cls = this.selectedClass;
    return (cls && cls.spell_list_l1) || [];
  }),

  spellPickSlots: computed('requiredSpellPicks', 'spellPicks.[]', function() {
    let n = this.requiredSpellPicks || 0;
    let picks = this.spellPicks || [];
    let slots = [];
    for (let i = 0; i < n; i++) {
      slots.push({ index: i + 1, spell: picks[i] || '' });
    }
    return slots;
  }),

  spellPicksFilled: computed('spellPicks.[]', function() {
    return (this.spellPicks || []).filter(s => s).length;
  }),

  thiefSkillsForClass: computed('selectedClass', 'osr_rpg.thief_skill_defs', function() {
    let cls = this.selectedClass;
    if (!cls || cls.skill_system !== 'd6') { return []; }
    let keys = cls.skill_set || [];
    if (keys.includes('all_eight')) {
      return this.get('osr_rpg.thief_skill_defs') || [];
    }
    let defs = this.get('osr_rpg.thief_skill_defs') || [];
    return defs.filter(d => keys.includes(d.key));
  }),

  thiefPointsSpent: computed('thiefAllocations.[]', 'thiefAllocations.@each.points', function() {
    let allocs = this.thiefAllocations || [];
    return allocs.reduce((sum, a) => sum + (parseInt(a.points, 10) || 0), 0);
  }),

  thiefPointsRemaining: computed('thiefPointsSpent', 'l1ExpertisePoints', function() {
    let total = this.l1ExpertisePoints || 4;
    return total - this.thiefPointsSpent;
  }),

  isPoolMode: computed('rollMode', function() {
    return this.rollMode === 'pool';
  }),

  unmetRequirementCount: computed('abilityStats.@each.failsMin', function() {
    return (this.abilityStats || []).filter(s => s.failsMin).length;
  }),

  abilityStats: computed(
    'osr_rpg.abilities',
    'abilityScores',
    'abilityRolls',
    'rollingAbility',
    'selectedClass',
    'poolAssignments',
    'scorePool',
    'rollMode',
    'abilityModifiers',
    function() {
      let abilities = this.get('osr_rpg.abilities') || [];
      let scores = this.abilityScores || {};
      let rolls = this.abilityRolls || {};
      let cls = this.selectedClass;
      let minScores = (cls && cls.min_scores) || {};
      let primes = (cls && cls.prime_reqs) || [];
      let mods = this.abilityModifiers;
      let rolling = this.rollingAbility;
      let pool = this.scorePool || [];
      let assignments = this.poolAssignments || {};

      return abilities.map(ab => {
        let score = scores[ab];
        let mod = score ? (mods[String(score)] ?? 0) : null;
        let modStr = mod === null ? '' : (mod >= 0 ? `+${mod}` : `${mod}`);
        let min = minScores[ab] || minScores[ab && ab.toString()];
        let failsMin = min && score && parseInt(score, 10) < parseInt(min, 10);
        let isPrime = primes.includes(ab);
        let scoreClass = 'osr-rpg-score-mid';
        if (score) {
          if (parseInt(score, 10) <= 8) {
            scoreClass = 'osr-rpg-score-low';
          } else if (parseInt(score, 10) >= 15) {
            scoreClass = 'osr-rpg-score-high';
          }
        }
        let roll = rolls[ab];
        let breakdown = roll ? `${roll.dice.join(' + ')} = ${roll.total}` : '';
        let cellClass = [scoreClass];
        if (failsMin) { cellClass.push('osr-rpg-stat-fail'); }
        if (isPrime) { cellClass.push('osr-rpg-stat-prime'); }
        if (rolling === ab) { cellClass.push('osr-rpg-rolling'); }

        let fullName = ABILITY_NAMES[ab] || ab;
        let tooltip = fullName;
        if (min) {
          tooltip += ` — min ${min}`;
        }
        if (isPrime) {
          tooltip += ' — prime requisite';
        }

        let poolAssigned = assignments[ab] !== null && assignments[ab] !== undefined && assignments[ab] !== '';

        return {
          key: ab,
          label: ab.toUpperCase(),
          fullName: fullName,
          tooltip: tooltip,
          score: score,
          modifier: mod,
          modStr: modStr,
          min: min,
          failsMin: failsMin,
          isPrime: isPrime,
          scoreClass: scoreClass,
          cellClass: cellClass.join(' '),
          breakdown: breakdown,
          poolValue: assignments[ab],
          poolAssigned: poolAssigned
        };
      });
    }
  ),

  unassignedPoolChips: computed('scorePool', 'poolAssignments', function() {
    let pool = this.scorePool || [];
    let assignments = this.poolAssignments || {};
    let usedIds = new Set(Object.values(assignments).filter(v => v !== null && v !== ''));
    return pool
      .filter(entry => !usedIds.has(String(entry.id)))
      .map(entry => ({
        ...entry,
        label: `${entry.dice.join('+')} = ${entry.total}`
      }));
  }),

  buildThiefAllocEntry(d, points) {
    let pts = parseInt(points, 10) || 0;
    let chance = 1 + pts;
    let pips = [];
    for (let i = 0; i < 6; i++) {
      pips.push(i < chance);
    }
    return {
      key: d.key,
      name: d.name,
      points: pts,
      chance: chance,
      atMax: chance >= 5,
      pips: pips
    };
  },

  initThiefAllocations: function() {
    let existing = this.get('osr_rpg.thief_skill_allocations') || {};
    let skills = this.thiefSkillsForClass || [];
    let allocs = skills.map(d => this.buildThiefAllocEntry(d, existing[d.key] || 0));
    this.set('thiefAllocations', A(allocs));
  },

  initShopCart() {
    let cart = { ...(this.get('osr_rpg.inventory') || {}) };
    (this.get('osr_rpg.equipment') || []).forEach(item => {
      let key = item && (item.key || item);
      if (!key) { return; }
      cart[key] = (parseInt(cart[key], 10) || 0) + 1;
    });
    this.set('shopCart', cart);
  },

  buildInventoryPayload() {
    let cart = { ...(this.shopCart || {}) };
    (this.get('osr_rpg.equipment') || []).forEach(item => {
      let key = item && (item.key || item);
      if (!key) { return; }
      if (!(parseInt(cart[key], 10) > 0)) {
        cart[key] = 1;
      }
    });
    let payload = {};
    Object.keys(cart).forEach(key => {
      let qty = parseInt(cart[key], 10) || 0;
      if (qty > 0) {
        payload[key] = qty;
      }
    });
    return payload;
  },

  initSpellPicks() {
    let existing = this.get('osr_rpg.spell_book') || {};
    let l1 = existing['1'] || existing[1] || [];
    let cls = this.selectedClass;
    if (cls && cls.casting_type === 'restricted') {
      l1 = cls.l1_spells || [];
    }
    this.set('spellPicks', A((l1 || []).slice()));
  },

  buildSpellBookPayload() {
    let cls = this.selectedClass;
    if (!cls) { return {}; }
    if (cls.casting_type === 'arcane') {
      let picks = (this.spellPicks || []).filter(s => s);
      return picks.length ? { '1': picks } : {};
    }
    if (cls.casting_type === 'restricted') {
      return { '1': cls.l1_spells || [] };
    }
    return {};
  },

  spellSummaryForPreview() {
    let cls = this.selectedClass;
    if (!cls) { return null; }
    if (cls.casting_type === 'divine' && (cls.l1_spell_slots || 0) > 0) {
      return `Full ${this.divineTraditionLabel} list access`;
    }
    if (cls.casting_type === 'restricted') {
      return this.restrictedL1SpellLabel;
    }
    if (cls.casting_type === 'arcane') {
      let picks = (this.spellPicks || []).filter(s => s);
      return picks.length ? picks.join(', ') : null;
    }
    return null;
  },

  modifierFor(score) {
    if (!score) { return null; }
    let mods = this.abilityModifiers;
    return mods[String(score)] ?? 0;
  },

  hasAnyScores() {
    let scores = this.abilityScores || {};
    return Object.values(scores).some(v => v !== null && v !== undefined && v !== '');
  },

  playDiceSound() {
    if (!this._diceAudio) {
      this._diceAudio = new Audio('/sounds/osr-rpg-dice.mp3');
      this._diceAudio.volume = 0.5;
    }
    this._diceAudio.currentTime = 0;
    this._diceAudio.play().catch(() => {});
  },

  applyRollCountFromResponse(response) {
    if (response && response.ability_roll_count != null) {
      this.set('abilityRollCount', response.ability_roll_count);
    } else {
      this.set('abilityRollCount', (this.abilityRollCount || 0) + 1);
    }
  },

  async fetchRolls(abilities, pool = false) {
    let useServer = this.useServerRolls || this.requireServerRolls;
    if (useServer) {
      try {
        let args = pool ? { pool: true } : { abilities: abilities };
        let response = await this.gameApi.request('osrRpgRollAbilities', args);
        if (response && !response.error) {
          return response;
        }
      } catch (_e) {
        if (this.requireServerRolls) {
          throw _e;
        }
        // fall through to client rolls
      }
    }
    if (this.requireServerRolls) {
      return pool ? { pool: [] } : { rolls: {} };
    }
    if (pool) {
      let poolEntries = [];
      for (let i = 0; i < 6; i++) {
        let detail = roll3d6Client();
        poolEntries.push({ id: i, dice: detail.dice, total: detail.total, assigned_to: null });
      }
      return { pool: poolEntries };
    }
    let rolls = {};
    (abilities || []).forEach(ab => {
      rolls[ab] = roll3d6Client();
    });
    return { rolls: rolls };
  },

  applyRollResult(ab, result) {
    this.set('abilityRolls', { ...(this.get('abilityRolls') || {}), [ab]: result });
    this.set('abilityScores', { ...(this.get('abilityScores') || {}), [ab]: result.total });
  },

  syncPoolToScores() {
    let pool = this.scorePool || [];
    let assignments = this.poolAssignments || {};
    let scores = { ...(this.abilityScores || {}) };
    let rolls = { ...(this.abilityRolls || {}) };
    (this.get('osr_rpg.abilities') || []).forEach(ab => {
      let poolId = assignments[ab];
      if (poolId === null || poolId === undefined || poolId === '') {
        scores[ab] = null;
        delete rolls[ab];
        return;
      }
      let entry = pool.find(p => String(p.id) === String(poolId));
      if (entry) {
        scores[ab] = entry.total;
        rolls[ab] = { dice: entry.dice, total: entry.total };
      }
    });
    this.set('abilityScores', scores);
    this.set('abilityRolls', rolls);
  },

  onUpdate: function() {
    if (this.isPoolMode) {
      this.syncPoolToScores();
    }

    let scores = {};
    (this.get('osr_rpg.abilities') || []).forEach(ab => {
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
      class: this.get('osr_rpg.class'),
      alignment: this.get('osr_rpg.alignment'),
      ability_scores: scores,
      thief_skills: thief_skills,
      spell_book: this.buildSpellBookPayload(),
      inventory: this.buildInventoryPayload(),
      ability_roll_count: this.abilityRollCount || 0
    };
  },

  @action
  classChanged(val) {
    let prevClass = this.get('osr_rpg.class');
    let nextClass = val ? val.key : null;
    this.set('osr_rpg.class', nextClass);
    if (val && val.alignment_restrictions) {
      let current = this.get('osr_rpg.alignment');
      if (current && !val.alignment_restrictions.includes(current)) {
        this.set('osr_rpg.alignment', null);
      }
    }
    this.initThiefAllocations();
    this.initSpellPicks();
    if (prevClass !== nextClass && prevClass) {
      this.resetShopForClassChange();
    } else {
      this.initShopCart();
      this.bootstrapShopData();
    }
  },

  async resetShopForClassChange() {
    this.set('shopCart', {});
    let id = this.get('model.char.id');
    if (!id) {
      return;
    }
    try {
      let response = await this.gameApi.requestOne('osrRpgResetShop', { id: id });
      if (response && response.error) {
        return;
      }
      if (response) {
        let osr = {
          ...this.currentOsrRpgData(),
          ...response,
          class: this.get('osr_rpg.class'),
          inventory: {},
          equipment: []
        };
        this.setOsrRpgData(osr);
        this.set('shopCart', {});
      }
    } catch (_e) {
      this.set('shopCart', {});
    }
  },

  @action
  addShopItem(itemKey) {
    if ((this.goldRemaining || 0) <= 0) { return; }
    let cart = { ...(this.shopCart || {}) };
    cart[itemKey] = (cart[itemKey] || 0) + 1;
    this.set('shopCart', cart);
  },

  @action
  removeShopItem(itemKey) {
    let cart = { ...(this.shopCart || {}) };
    let qty = (cart[itemKey] || 0) - 1;
    if (qty <= 0) {
      delete cart[itemKey];
    } else {
      cart[itemKey] = qty;
    }
    this.set('shopCart', cart);
  },

  @action
  clearCartItem(itemKey) {
    let cart = { ...(this.shopCart || {}) };
    delete cart[itemKey];
    this.set('shopCart', cart);
  },

  @action
  spellPickChanged(slotIndex, event) {
    let spell = event.target.value;
    let picks = [...(this.spellPicks || [])];
    while (picks.length < slotIndex) { picks.push(''); }
    picks[slotIndex - 1] = spell;
    this.set('spellPicks', A(picks));
  },

  @action
  alignmentChanged(val) {
    this.set('osr_rpg.alignment', val);
  },

  @action
  abilityChanged(ab, event) {
    if (this.lockAbilityScores) { return; }
    let val = parseInt(event.target.value, 10);
    this.set('abilityScores', {
      ...(this.get('abilityScores') || {}),
      [ab]: isNaN(val) ? null : val
    });
  },

  updateThiefAlloc(skillKey, points) {
    let allocs = this.thiefAllocations || [];
    let idx = allocs.findIndex(a => a.key === skillKey);
    if (idx < 0) { return; }
    let pts = Math.max(0, parseInt(points, 10) || 0);
    let chance = 1 + pts;
    let pips = [];
    for (let i = 0; i < 6; i++) {
      pips.push(i < chance);
    }
    this.set(`thiefAllocations.${idx}.points`, pts);
    this.set(`thiefAllocations.${idx}.chance`, chance);
    this.set(`thiefAllocations.${idx}.atMax`, chance >= 5);
    this.set(`thiefAllocations.${idx}.pips`, pips);
  },

  @action
  incrementExpertise(skillKey) {
    if ((this.thiefPointsRemaining || 0) <= 0) { return; }
    let allocs = this.thiefAllocations || [];
    let entry = allocs.find(a => a.key === skillKey);
    if (!entry || entry.atMax) { return; }
    let pts = parseInt(entry.points, 10) || 0;
    this.updateThiefAlloc(skillKey, pts + 1);
  },

  @action
  decrementExpertise(skillKey) {
    let allocs = this.thiefAllocations || [];
    let entry = allocs.find(a => a.key === skillKey);
    if (!entry) { return; }
    let pts = parseInt(entry.points, 10) || 0;
    if (pts <= 0) { return; }
    this.updateThiefAlloc(skillKey, pts - 1);
  },

  @action
  rollModeChanged(mode) {
    this.set('rollMode', mode);
    this.set('scorePool', null);
    this.set('poolAssignments', {});
    this.set('abilityRolls', {});
  },

  @action
  useServerRollsChanged(event) {
    if (this.requireServerRolls) { return; }
    this.set('useServerRolls', event.target.checked);
  },

  @action
  async rollOneAbility(ab) {
    if (this.isRolling) { return; }
    this.playDiceSound();
    this.set('isRolling', true);
    this.set('rollingAbility', ab);
    try {
      let response = await this.fetchRolls([ab]);
      this.applyRollCountFromResponse(response);
      let result = response.rolls[ab];
      if (result) {
        this.applyRollResult(ab, result);
      }
      await delay(250);
    } finally {
      this.set('rollingAbility', null);
      this.set('isRolling', false);
    }
  },

  @action
  async rollAllAbilities() {
    if (this.isRolling) { return; }
    if (this.hasAnyScores() && !window.confirm('Replace your current ability scores with new rolls?')) {
      return;
    }

    this.set('isRolling', true);
    let abilities = this.get('osr_rpg.abilities') || [];
    try {
      let response = await this.fetchRolls(abilities);
      this.applyRollCountFromResponse(response);
      for (let ab of abilities) {
        this.playDiceSound();
        this.set('rollingAbility', ab);
        let result = response.rolls[ab];
        if (result) {
          this.applyRollResult(ab, result);
        }
        await delay(350);
      }
    } finally {
      this.set('rollingAbility', null);
      this.set('isRolling', false);
    }
  },

  @action
  async rollPool() {
    if (this.isRolling) { return; }
    if ((this.scorePool && this.scorePool.length) && !window.confirm('Replace your current score pool with new rolls?')) {
      return;
    }

    this.set('isRolling', true);
    try {
      this.playDiceSound();
      let response = await this.fetchRolls(null, true);
      this.applyRollCountFromResponse(response);
      this.set('scorePool', response.pool || []);
      this.set('poolAssignments', {});
      this.set('abilityRolls', {});
      let scores = {};
      (this.get('osr_rpg.abilities') || []).forEach(ab => { scores[ab] = null; });
      this.set('abilityScores', scores);
    } finally {
      this.set('isRolling', false);
    }
  },

  assignPoolEntry(abilityKey, poolId) {
    let assignments = { ...(this.poolAssignments || {}) };
    assignments[abilityKey] = String(poolId);
    this.set('poolAssignments', assignments);
    this.syncPoolToScores();
  },

  clearPoolAssignment(abilityKey) {
    let assignments = { ...(this.poolAssignments || {}) };
    delete assignments[abilityKey];
    this.set('poolAssignments', assignments);
    this.syncPoolToScores();
  },

  @action
  poolChipDragStart(entry, event) {
    event.dataTransfer.setData('text/pool-id', String(entry.id));
    event.dataTransfer.effectAllowed = 'move';
    this.set('draggingPoolId', entry.id);
  },

  @action
  poolChipDragEnd() {
    this.set('draggingPoolId', null);
    this.set('dragOverAbility', null);
  },

  @action
  abilityDragOver(abilityKey, event) {
    event.preventDefault();
    event.dataTransfer.dropEffect = 'move';
    this.set('dragOverAbility', abilityKey);
  },

  @action
  abilityDragLeave(abilityKey, event) {
    if (event.currentTarget.contains(event.relatedTarget)) {
      return;
    }
    if (this.dragOverAbility === abilityKey) {
      this.set('dragOverAbility', null);
    }
  },

  @action
  abilityDrop(abilityKey, event) {
    event.preventDefault();
    let poolId = event.dataTransfer.getData('text/pool-id');
    if (poolId) {
      this.assignPoolEntry(abilityKey, poolId);
    }
    this.set('dragOverAbility', null);
    this.set('draggingPoolId', null);
  },

  @action
  clearPoolAssignmentAction(abilityKey) {
    this.clearPoolAssignment(abilityKey);
  },

});
