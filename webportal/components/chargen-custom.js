import Component from '@ember/component';
import { computed } from '@ember/object';

export default Component.extend({
  tagName: '',

  osrRpgUpdateCallback: null,

  didInsertElement() {
    this._super(...arguments);
    let self = this;
    this.set('updateCallback', function() {
      return self.onUpdate();
    });
  },

  chargenModel: computed('char', 'cgInfo', function() {
    return {
      char: this.char,
      cgInfo: this.cgInfo
    };
  }),

  onUpdate() {
    let payload = this.osrRpgUpdateCallback ? this.osrRpgUpdateCallback() : null;
    return payload ? { osr_rpg: payload } : {};
  }
});
