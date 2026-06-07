import Component from '@ember/component';
import { computed } from '@ember/object';

export default Component.extend({
  tagName: '',

  sheet: computed('char.osr_rpg', function() {
    return this.get('char.osr_rpg') || {};
  })
});
