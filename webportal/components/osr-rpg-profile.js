import Component from '@ember/component';
import { computed } from '@ember/object';
import { action } from '@ember/object';
import { inject as service } from '@ember/service';

export default Component.extend({
  tagName: '',
  gameApi: service(),
  flashMessages: service(),
  session: service(),
  isLeveling: false,

  sheet: computed('char.osr_rpg', function() {
    return this.get('char.osr_rpg') || {};
  }),

  isOwnProfile: computed('char.name', 'session.data.authenticated.name', function() {
    return this.get('char.name') === this.get('session.data.authenticated.name');
  }),

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
        if (response.sheet) {
          this.set('char.osr_rpg', response.sheet);
        }
        this.flashMessages.success(`Level ${response.level}! +${response.hp_added} HP.`);
      })
      .finally(() => {
        this.set('isLeveling', false);
      });
  }
});
