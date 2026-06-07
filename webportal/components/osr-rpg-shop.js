import Component from '@ember/component';
import { computed, set } from '@ember/object';
import { action } from '@ember/object';
import { inject as service } from '@ember/service';

export default Component.extend({
  tagName: '',
  gameApi: service(),
  flashMessages: service(),
  isBusy: false,

  eligible: computed('model.eligible', function() {
    return this.get('model.eligible') === true;
  }),

  gold: computed('model.gold', function() {
    return this.get('model.gold') || 0;
  }),

  arcaneCaster: computed('model.arcane_caster', function() {
    return this.get('model.arcane_caster') === true;
  }),

  catalogSections: computed('model.catalog_sections.[]', function() {
    return this.get('model.catalog_sections') || [];
  }),

  sellableInventory: computed('model.inventory.[]', function() {
    return this.get('model.inventory') || [];
  }),

  equippedGear: computed('model.equipment.[]', function() {
    return this.get('model.equipment') || [];
  }),

  applyState(response) {
    if (!response) { return; }
    Object.keys(response).forEach(key => {
      set(this.model, key, response[key]);
    });
  },

  canBuyItem(item) {
    if (!item) { return false; }
    let cost = item.cost || 0;
    if (cost <= 0 || this.gold < cost) { return false; }
    if (item.arcane_only && !this.arcaneCaster) { return false; }
    return true;
  },

  buyDisabledReason(item) {
    if (!item) { return ''; }
    if (item.arcane_only && !this.arcaneCaster) {
      return 'Arcane casters only';
    }
    if ((item.cost || 0) > this.gold) {
      return 'Insufficient gold';
    }
    return '';
  },

  @action
  refreshShop() {
    return this.gameApi.requestOne('osrRpgShopState', {}, null)
      .then((response) => {
        if (response.error) {
          this.flashMessages.danger(response.error);
          return;
        }
        this.applyState(response);
      });
  },

  @action
  buyItem(item) {
    if (this.isBusy || !this.canBuyItem(item)) { return; }
    this.set('isBusy', true);
    this.gameApi.requestOne('osrRpgShopBuy', { item: item.key, qty: 1 }, null)
      .then((response) => {
        if (response.error) {
          this.flashMessages.danger(response.error);
          return;
        }
        this.applyState(response);
        if (response.message) {
          this.flashMessages.success(response.message);
        }
      })
      .finally(() => {
        this.set('isBusy', false);
      });
  },

  @action
  sellItem(item) {
    if (this.isBusy || !item || (item.qty || 0) <= 0) { return; }
    this.set('isBusy', true);
    this.gameApi.requestOne('osrRpgShopSell', { item: item.key, qty: 1 }, null)
      .then((response) => {
        if (response.error) {
          this.flashMessages.danger(response.error);
          return;
        }
        this.applyState(response);
        if (response.message) {
          this.flashMessages.success(response.message);
        }
      })
      .finally(() => {
        this.set('isBusy', false);
      });
  }
});
